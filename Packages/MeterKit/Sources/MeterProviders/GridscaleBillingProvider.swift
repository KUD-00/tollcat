import Foundation
import MeterCore

/// gridscale 本账期累计价（Public API 各资源 `current_price`）。
///
/// 文档：https://gridscale.io — customer Public API（非 partner Management）。
/// 认证：`X-Auth-UserId` + `X-Auth-Token`（`accountID` + `apiToken`）。
/// `current_price` = 自上期账单以来本周期价格；可选附带 `usage_in_minutes`。
/// 货币按 EUR（gridscale 目录价）；跳过 partner/invoices Management API。
public struct GridscaleBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.gridscale }
    public static let apiHost = "api.gridscale.io"
    static let resourcePaths = [
        "/objects/servers",
        "/objects/storages",
        "/objects/ips",
        "/objects/loadbalancers",
        "/objects/paas",
        "/objects/networks",
    ]

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
        let userID = try RequiredCredential.value(.accountID, in: credential, providerID: .gridscale)
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .gridscale)
        let headers = [
            "X-Auth-UserId": userID,
            "X-Auth-Token": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        try currencies.observe("EUR", providerID: .gridscale)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for path in Self.resourcePaths {
            let rows = try await loadResources(path: path, headers: headers)
            let category = path.split(separator: "/").last.map(String.init) ?? "resource"
            for row in rows {
                let amount = row.current_price?.value ?? 0
                guard amount != 0 else { continue }
                currentTotal += amount
                let label = row.name ?? row.object_uuid ?? category
                lines.add(
                    SpendLine(
                        category: category,
                        label: label,
                        amountUSD: Money(usd: amount)
                    )
                )
            }
        }

        if currentTotal != 0 {
            daily.add(day: current.start, amount: Money(usd: currentTotal))
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .gridscale
        )
        return Snapshot(
            providerID: .gridscale,
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

    private func loadResources(path: String, headers: [String: String]) async throws -> [Resource] {
        let url = ProviderURL.https(host: Self.apiHost, path: path)
        let data: Data
        do {
            data = try await ProviderHTTP.get(
                url: url,
                headers: headers,
                client: httpClient,
                providerID: .gridscale
            )
        } catch {
            // Optional collections may 404; auth failures surface on /objects/servers first.
            if path != Self.resourcePaths[0] { return [] }
            throw error
        }
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Shape A: { "servers": { "uuid": { ... } } }
            for (_, value) in dict {
                if let map = value as? [String: [String: Any]] {
                    return map.values.compactMap { Self.decodeResource($0) }
                }
                if let list = value as? [[String: Any]] {
                    return list.compactMap { Self.decodeResource($0) }
                }
            }
        }
        if let wrapped = try? ProviderHTTP.decode(ResourceMap.self, from: data, providerID: .gridscale) {
            return wrapped.allResources
        }
        return (try? ProviderHTTP.decode([Resource].self, from: data, providerID: .gridscale)) ?? []
    }

    static func decodeResource(_ raw: [String: Any]) -> Resource? {
        guard let json = try? JSONSerialization.data(withJSONObject: raw) else { return nil }
        return try? JSONDecoder().decode(Resource.self, from: json)
    }

    struct ResourceMap: Decodable, Sendable {
        var servers: [String: Resource]?
        var storages: [String: Resource]?
        var ips: [String: Resource]?
        var loadbalancers: [String: Resource]?
        var paas: [String: Resource]?
        var networks: [String: Resource]?

        var allResources: [Resource] {
            [servers, storages, ips, loadbalancers, paas, networks]
                .compactMap { $0 }
                .flatMap { Array($0.values) }
        }
    }

    struct Resource: Decodable, Sendable {
        var object_uuid: String?
        var name: String?
        var current_price: FlexibleDecimal?
        var usage_in_minutes: FlexibleDecimal?
    }
}
