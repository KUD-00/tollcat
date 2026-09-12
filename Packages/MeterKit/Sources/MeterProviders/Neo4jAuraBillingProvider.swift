import Foundation
import MeterCore

/// Neo4j Aura 本月账单用量。
///
/// 认证：Client ID + Client Secret 走 OAuth `client_credentials` 换 Bearer。
/// 创建页：`https://console.neo4j.io/account/client-credentials`
/// 组织 UUID 没填就 `GET /v2beta1/organizations` 自己列。
///
/// 账单：`GET /v2beta1/organizations/{org_id}/billing/usage`
/// Spec：https://api.neo4j.io/v2beta1/spec.json
/// `end` 必须早于现在——下月 1 号会 400。
///
/// **每天每组织 10 次。** 用量接口按天刷新、最多滞后 48 小时。一次刷新只打这一下
/// （当前月或整段历史都是一个窗口），不要按月拆。见 `minimumRefreshInterval`。
public struct Neo4jAuraBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.neo4j }
    public static let apiHost = "api.neo4j.io"
    static let maxPages = 40

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .neo4j)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .neo4j)
        let pinnedOrg = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let projectID = credential.value(for: .projectID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let window = CalendarMonthWindow.spanning(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        let token = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: (id: clientID, secret: clientSecret),
            form: ["grant_type": "client_credentials"],
            client: httpClient,
            providerID: .neo4j
        )
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let orgID: String
        if let pinnedOrg, !pinnedOrg.isEmpty {
            orgID = pinnedOrg
        } else {
            orgID = try await loadFirstOrganizationID(headers: headers)
        }

        let rows = try await loadUsage(
            orgID: orgID,
            window: window,
            now: now,
            projectID: projectID,
            headers: headers
        )

        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for row in rows {
            let amount = Self.usdAmount(row)
            guard amount != 0 else { continue }
            let stamp = row.charge_period_start.flatMap {
                BillingDateParser.parse($0, calendar: calendar)
            } ?? window.start
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                let label = [
                    row.resource_name,
                    row.service_name,
                    row.base_sku,
                ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "usage"
                lines.add(
                    SpendLine(
                        category: row.resource_type ?? "usage",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        return Snapshot(
            providerID: .neo4j,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily,
            lines: lines.snapshot
        )
    }

    private func loadFirstOrganizationID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.organizationsURL,
            headers: headers,
            client: httpClient,
            providerID: .neo4j
        )
        let payload = try ProviderHTTP.decode(OrganizationList.self, from: data, providerID: .neo4j)
        // 多个组织时用第一个。账单额度按组织算，不在这里对每家打一遍。
        guard let id = payload.data?.first?.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !id.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .neo4j)
        }
        return id
    }

    private func loadUsage(
        orgID: String,
        window: CalendarMonthWindow,
        now: Date,
        projectID: String?,
        headers: [String: String]
    ) async throws -> [UsageRow] {
        var pageToken = ""
        var pages = 0
        var rows: [UsageRow] = []
        while true {
            let data = try await ProviderHTTP.get(
                url: Self.usageURL(
                    orgID: orgID,
                    window: window,
                    now: now,
                    pageToken: pageToken,
                    projectID: projectID
                ),
                headers: headers,
                client: httpClient,
                providerID: .neo4j
            )
            let payload = try ProviderHTTP.decode(UsageList.self, from: data, providerID: .neo4j)
            rows.append(contentsOf: payload.data ?? [])
            pages += 1
            let next = payload.links?.next?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if next.isEmpty {
                break
            }
            if pages >= Self.maxPages {
                throw ProviderError.malformedResponse(providerID: .neo4j)
            }
            if let url = URL(string: next), url.host == Self.apiHost {
                if let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "page_token" })?
                    .value
                {
                    pageToken = token
                } else {
                    break
                }
            } else {
                pageToken = next
            }
        }
        return rows
    }

    /// Prefer `list_cost`; credits/ACU/USD are 1:1 USD.
    static func usdAmount(_ row: UsageRow) -> Decimal {
        let cost = row.list_cost?.value ?? 0
        guard cost != 0 else { return 0 }
        return cost
    }

    /// 官方要求 `end` 早于现在。当前月用 now，过去的月用该月 `nextStart`。
    static func usageEnd(window: CalendarMonthWindow, now: Date) -> Date {
        let end = min(window.nextStart, now)
        return end < now ? end : now.addingTimeInterval(-1)
    }

    static let tokenURL = ProviderURL.https(
        host: apiHost,
        path: "/oauth/token"
    )

    static let organizationsURL = ProviderURL.https(
        host: apiHost,
        path: "/v2beta1/organizations"
    )

    static func usageURL(
        orgID: String,
        window: CalendarMonthWindow,
        now: Date,
        pageToken: String,
        projectID: String?
    ) -> URL {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "start", value: window.rfc3339(window.start)),
            URLQueryItem(name: "end", value: window.rfc3339(usageEnd(window: window, now: now))),
            URLQueryItem(name: "page_limit", value: "100"),
            URLQueryItem(name: "page_token", value: pageToken),
        ]
        if let projectID, !projectID.isEmpty {
            query.append(URLQueryItem(name: "project_id", value: projectID))
        }
        return ProviderURL.https(
            host: apiHost,
            path: "/v2beta1/organizations/\(orgID)/billing/usage",
            query: query
        )
    }

    struct OrganizationList: Decodable, Sendable {
        var data: [Organization]?
    }

    struct Organization: Decodable, Sendable {
        var id: String?
        var name: String?
    }

    struct UsageList: Decodable, Sendable {
        var data: [UsageRow]?
        var links: Links?
    }

    struct Links: Decodable, Sendable {
        var next: String?
        var selfLink: String?
        var first: String?

        enum CodingKeys: String, CodingKey {
            case next, first
            case selfLink = "self"
        }
    }

    struct UsageRow: Decodable, Sendable {
        var base_sku: String?
        var list_cost: FlexibleDecimal?
        var list_unit_price: FlexibleDecimal?
        var pricing_currency: String?
        var consumed_quantity: FlexibleDecimal?
        var charge_period_start: String?
        var charge_period_end: String?
        var resource_name: String?
        var resource_type: String?
        var service_name: String?
        var project_name: String?
    }
}
