import Foundation
import MeterCore

/// Name.com Core v1：`GET /core/v1/orders` 列表 + `GET /core/v1/orders/{orderId}` →
/// `finalAmount` + `currency`（USD|CNY）。
///
/// 文档：https://docs.name.com/api/v1/reference/orders/get-order
/// 认证：HTTP Basic（`username`=`email` 或 `accountID`，`password`=`apiToken`/`apiKey`）。
/// Host：`api.name.com`。
public struct NameComBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.namecom }

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
        let username = (credential.value(for: .email) ?? credential.value(for: .accountID))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let user = try {
            if let username, !username.isEmpty { return username }
            return try RequiredCredential.value(.accountID, in: credential, providerID: .namecom)
        }()
        let secret = (credential.value(for: .apiToken) ?? credential.value(for: .apiKey))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let password = try {
            if let secret, !secret.isEmpty { return secret }
            return try RequiredCredential.value(.apiToken, in: credential, providerID: .namecom)
        }()
        let basic = Data("\(user):\(password)".utf8).base64EncodedString()
        let headers = [
            "Authorization": "Basic \(basic)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let orderIDs = try await listOrderIDs(headers: headers)
        for orderID in orderIDs.prefix(100) {
            guard let order = try? await getOrder(id: orderID, headers: headers) else { continue }
            let amount = order.finalAmount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe(order.currency, providerID: .namecom)
            let stamp = order.createDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = order.orderId.map(String.init) ?? orderID
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
            providerID: .namecom
        )
        return Snapshot(
            providerID: .namecom,
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

    private func listOrderIDs(headers: [String: String]) async throws -> [String] {
        let url = ProviderURL.https(host: "api.name.com", path: "/core/v1/orders")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .namecom
        )
        if let page = try? ProviderHTTP.decode(OrderList.self, from: data, providerID: .namecom) {
            return (page.orders ?? []).compactMap { order in
                if let id = order.orderId { return String(id) }
                return order.id
            }
        }
        if let ids = try? ProviderHTTP.decode([Int].self, from: data, providerID: .namecom) {
            return ids.map(String.init)
        }
        return []
    }

    private func getOrder(id: String, headers: [String: String]) async throws -> Order {
        let url = ProviderURL.https(host: "api.name.com", path: "/core/v1/orders/\(id)")
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .namecom
        )
        return try ProviderHTTP.decode(Order.self, from: data, providerID: .namecom)
    }

    struct OrderList: Decodable, Sendable {
        var orders: [Order]?
    }

    struct Order: Decodable, Sendable {
        var orderId: Int?
        var id: String?
        var finalAmount: FlexibleDecimal?
        var currency: String?
        var createDate: String?
    }
}
