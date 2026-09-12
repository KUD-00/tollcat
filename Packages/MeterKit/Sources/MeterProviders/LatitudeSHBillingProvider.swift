import Foundation
import MeterCore

/// Latitude.sh 项目周期用量花费（`GET /billing/usage?filter[project]=…`）。
///
/// 文档：https://www.latitude.sh/docs/api-reference/get-billing-usage
/// 认证：`Authorization: Bearer <API key>`。
/// Host：`api.latitude.sh`。
/// 金额：`attributes.price` / `amount`（cents）为**周期用量花费**；忽略 `available_credit_balance`（预付余额≠LIVE）。
/// 币种：项目 `team.currency.code`（缺省 USD）。可凭 `projectID` 限定项目，否则汇总全部项目。
public struct LatitudeSHBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.latitudesh }
    public static let apiHost = "api.latitude.sh"
    static let centsPerUnit = Decimal(100)

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar
    public var rateSource: SharedExchangeRates

    public init(
        httpClient: any HTTPClient,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar,
        rateSource: SharedExchangeRates
    ) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
        self.rateSource = rateSource
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let token: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .latitudesh) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiToken, in: credential, providerID: .latitudesh)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/vnd.api+json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0
        _ = horizon

        let projects: [Project]
        if let only = try? RequiredCredential.value(.projectID, in: credential, providerID: .latitudesh) {
            projects = [Project(id: only, currencyCode: nil, name: only)]
        } else {
            projects = try await loadProjects(headers: headers)
        }

        for project in projects {
            let usage = try await loadUsage(projectID: project.id, headers: headers)
            let cents = usage.data?.attributes?.price?.value
                ?? usage.data?.attributes?.amount?.value
                ?? 0
            guard cents != 0 else { continue }
            let amount = cents / Self.centsPerUnit
            try currencies.observe(project.currencyCode ?? "USD", providerID: .latitudesh)
            let periodStart = usage.data?.attributes?.period?.start
                .flatMap { BillingDateParser.parse($0, calendar: calendar) }
            let stamp = periodStart ?? current.start
            let label = project.name ?? project.id
            // 周期用量：若 period 与本月重叠或无法解析，计入本月。
            let inCurrent: Bool
            if let start = usage.data?.attributes?.period?.start.flatMap({ BillingDateParser.parse($0, calendar: calendar) }),
               let end = usage.data?.attributes?.period?.end.flatMap({ BillingDateParser.parse($0, calendar: calendar) }) {
                inCurrent = start <= current.endInclusive && end >= current.start
            } else {
                inCurrent = current.contains(stamp)
            }
            if inCurrent {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "usage",
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .latitudesh
        )
        return Snapshot(
            providerID: .latitudesh,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: converted.money,
            dailyUSD: currencies.scaled(daily.snapshotDaily, by: converted.usdPerUnit),
            converted: currencies.needsConversionNote ? converted : nil,
            lines: lines.snapshot
        )
    }

    private func loadProjects(headers: [String: String]) async throws -> [Project] {
        let data = try await ProviderHTTP.get(
            url: Self.projectsURL,
            headers: headers,
            client: httpClient,
            providerID: .latitudesh
        )
        let envelope = try ProviderHTTP.decode(ProjectList.self, from: data, providerID: .latitudesh)
        return (envelope.data ?? []).compactMap { item in
            guard let id = item.id else { return nil }
            return Project(
                id: id,
                currencyCode: item.attributes?.team?.currency?.code,
                name: item.attributes?.name ?? item.attributes?.slug
            )
        }
    }

    private func loadUsage(projectID: String, headers: [String: String]) async throws -> UsageEnvelope {
        let data = try await ProviderHTTP.get(
            url: Self.usageURL(projectID: projectID),
            headers: headers,
            client: httpClient,
            providerID: .latitudesh
        )
        return try ProviderHTTP.decode(UsageEnvelope.self, from: data, providerID: .latitudesh)
    }

    static let projectsURL = ProviderURL.https(host: apiHost, path: "/projects")

    static func usageURL(projectID: String) -> URL {
        ProviderURL.https(
            host: apiHost,
            path: "/billing/usage",
            query: [URLQueryItem(name: "filter[project]", value: projectID)]
        )
    }

    struct Project: Sendable {
        var id: String
        var currencyCode: String?
        var name: String?
    }

    struct ProjectList: Decodable, Sendable {
        var data: [ProjectResource]?
    }

    struct ProjectResource: Decodable, Sendable {
        var id: String?
        var attributes: ProjectAttributes?
    }

    struct ProjectAttributes: Decodable, Sendable {
        var name: String?
        var slug: String?
        var team: TeamInclude?
    }

    struct TeamInclude: Decodable, Sendable {
        var currency: CurrencyCode?
    }

    struct CurrencyCode: Decodable, Sendable {
        var code: String?
    }

    struct UsageEnvelope: Decodable, Sendable {
        var data: UsageResource?
    }

    struct UsageResource: Decodable, Sendable {
        var attributes: UsageAttributes?
    }

    struct UsageAttributes: Decodable, Sendable {
        var period: Period?
        var amount: FlexibleDecimal?
        var price: FlexibleDecimal?
        var available_credit_balance: FlexibleDecimal?
        var project: ProjectRef?
    }

    struct Period: Decodable, Sendable {
        var start: String?
        var end: String?
    }

    struct ProjectRef: Decodable, Sendable {
        var id: String?
        var name: String?
    }
}
