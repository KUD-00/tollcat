import Foundation
import MeterCore

/// ClickHouse Cloud 本月花费。
///
/// 文档：`GET /v1/organizations` 再 `GET /v1/organizations/{id}/usageCost`
/// 认证：HTTP Basic，用户名是 Key ID，密码是 Key Secret。
///
/// `grandTotalCHC` 的单位是 ClickHouse Credit，**1 CHC = $1**。日线按
/// `costs[].date` 把当天 metrics 里的 CHC 加起来。区间含首尾，最长 31 天。
public struct ClickHouseBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.clickhouse }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
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
        let keyID = try RequiredCredential.value(.clientID, in: credential, providerID: .clickhouse)
        let secret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .clickhouse)
        let headers = [
            "Authorization": Self.basicAuthorization(id: keyID, secret: secret),
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )

        let organizationID: String
        if let pinned = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !pinned.isEmpty {
            organizationID = pinned
        } else {
            organizationID = try await loadFirstOrganizationID(headers: headers)
        }

        var daily = DailySpendAccumulator()
        var currentGrand: Decimal?
        for month in months {
            let data = try await ProviderHTTP.get(
                url: Self.usageCostURL(organizationID: organizationID, window: month, calendar: calendar),
                headers: headers,
                client: httpClient,
                providerID: .clickhouse
            )
            let envelope = try ProviderHTTP.decode(UsageCostEnvelope.self, from: data, providerID: .clickhouse)
            let result = envelope.result
            if month.start == current.start {
                currentGrand = result?.grandTotalCHC?.value
            }
            for row in result?.costs ?? [] {
                let amount = row.metrics?.total ?? 0
                guard amount != 0 else { continue }
                let day = row.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? month.start
                daily.add(day: month.contains(day) ? day : month.clamp(day), amount: Money(usd: amount))
            }
        }
        let monthSpend = daily.total(in: current, calendar: calendar)
        return Snapshot(
            providerID: .clickhouse,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentGrand ?? monthSpend.usd),
            dailyUSD: daily.snapshotDaily
        )
    }

    private func loadFirstOrganizationID(headers: [String: String]) async throws -> String {
        let data = try await ProviderHTTP.get(
            url: Self.organizationsURL,
            headers: headers,
            client: httpClient,
            providerID: .clickhouse
        )
        let payload = try ProviderHTTP.decode(OrganizationList.self, from: data, providerID: .clickhouse)
        guard let id = payload.result?.first?.id, !id.isEmpty else {
            throw ProviderError.malformedResponse(providerID: .clickhouse)
        }
        return id
    }

    static func basicAuthorization(id: String, secret: String) -> String {
        let raw = Data("\(id):\(secret)".utf8).base64EncodedString()
        return "Basic \(raw)"
    }

    static let organizationsURL = URL(string: "https://api.clickhouse.cloud/v1/organizations")!

    static func usageCostURL(
        organizationID: String,
        window: CalendarMonthWindow,
        calendar: Calendar
    ) -> URL {
        ProviderURL.https(
            host: "api.clickhouse.cloud",
            path: "/v1/organizations/\(organizationID)/usageCost",
            query: [
                URLQueryItem(name: "from_date", value: window.dayString(window.start, calendar: calendar)),
                URLQueryItem(name: "to_date", value: window.dayString(window.endInclusive, calendar: calendar)),
            ]
        )
    }

    struct OrganizationList: Decodable, Sendable {
        var result: [Organization]?
    }

    struct Organization: Decodable, Sendable {
        var id: String?
        var name: String?
    }

    struct UsageCostEnvelope: Decodable, Sendable {
        var result: UsageCost?
    }

    struct UsageCost: Decodable, Sendable {
        var grandTotalCHC: FlexibleDecimal?
        var costs: [CostRow]?
    }

    struct CostRow: Decodable, Sendable {
        var date: String?
        var metrics: Metrics?
    }

    struct Metrics: Decodable, Sendable {
        var values: [String: Decimal]

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode([String: FlexibleDecimal].self)) ?? [:]
            values = raw.mapValues(\.value)
        }

        var total: Decimal {
            values.values.reduce(0, +)
        }
    }
}
