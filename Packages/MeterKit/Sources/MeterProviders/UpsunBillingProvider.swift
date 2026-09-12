import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Upsun（原 Platform.sh）组织订单（`GET /organizations/{org}/orders`）。
///
/// 文档：https://developer.upsun.com/api-reference/orders/list-orders
/// 认证：API token → `POST https://auth.upsun.com/oauth2/token`（`grant_type=api_token`，Basic `platform-api-user:`）。
/// Host：`api.upsun.com`。
/// 金额：`total` + `currency`；周期 `billing_period_start` / `billing_period_end`。
/// **忽略**已弃用的 invoices 列表（无币种字段）。跳过 `canceled`。
/// 凭据：`apiToken`/`apiKey` + `accountID`（organization id）。
public struct UpsunBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.upsun }
    public static let apiHost = "api.upsun.com"
    public static let authHost = "auth.upsun.com"
    public static let oauthClientID = "platform-api-user"

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
        let apiToken: String
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .upsun) {
            apiToken = primary
        } else {
            apiToken = try RequiredCredential.value(.apiKey, in: credential, providerID: .upsun)
        }
        let orgID = try RequiredCredential.value(.accountID, in: credential, providerID: .upsun)
        let bearer = try await ProviderOAuth.clientCredentialsToken(
            url: Self.tokenURL,
            basic: (id: Self.oauthClientID, secret: ""),
            form: [
                "grant_type": "api_token",
                "api_token": apiToken,
            ],
            client: httpClient,
            providerID: .upsun
        )
        let headers = [
            "Authorization": "Bearer \(bearer)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let orders = try await loadOrders(orgID: orgID, headers: headers)
        for order in orders {
            let status = (order.status ?? "").lowercased()
            if status == "canceled" { continue }
            let amount = order.total?.value ?? 0
            guard amount != 0 else { continue }
            let currency = order.currency?.trimmingCharacters(in: .whitespacesAndNewlines)
            try currencies.observe((currency?.isEmpty == false) ? currency! : "USD", providerID: .upsun)
            let stamp = order.billing_period_start.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? order.paid_on.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = order.billing_period_label?.formatted
                ?? order.id
                ?? "order"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "order",
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

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .upsun
        )
        return Snapshot(
            providerID: .upsun,
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

    private func loadOrders(orgID: String, headers: [String: String]) async throws -> [Order] {
        let data = try await ProviderHTTP.get(
            url: Self.ordersURL(orgID: orgID),
            headers: headers,
            client: httpClient,
            providerID: .upsun
        )
        let envelope = try ProviderHTTP.decode(OrderList.self, from: data, providerID: .upsun)
        return envelope.items ?? []
    }

    public static let tokenURL = ProviderURL.https(host: authHost, path: "/oauth2/token")
    public static func ordersURL(orgID: String) -> URL {
        ProviderURL.https(host: apiHost, path: "/organizations/\(orgID)/orders")
    }

    struct OrderList: Decodable, Sendable {
        var items: [Order]?
    }

    struct Order: Decodable, Sendable {
        var id: String?
        var status: String?
        var total: FlexibleDecimal?
        var currency: String?
        var billing_period_start: String?
        var billing_period_end: String?
        var paid_on: String?
        var billing_period_label: PeriodLabel?
        var invoiced: Bool?
    }

    struct PeriodLabel: Decodable, Sendable {
        var formatted: String?
        var month: String?
        var year: String?
    }
}
