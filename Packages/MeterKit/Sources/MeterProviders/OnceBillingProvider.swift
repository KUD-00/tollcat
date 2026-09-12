import Foundation
import MeterCore

/// 1NCE Management API：`GET /management-api/v1/orders` → `invoice_amount` + ISO `currency`。
/// 不含 Data Streamer cost。
///
/// 文档：https://help.1nce.com/api/order-management/
/// 认证：`POST /oauth/token`（Basic clientID:clientSecret，grant_type=client_credentials）→ Bearer。
/// Host：`api.1nce.com`。
public struct OnceBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.once }

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
        let token = try await accessToken(credential: credential)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var page = 1
        while page <= 50 {
            let orders = try await loadOrders(page: page, headers: headers)
            if orders.isEmpty { break }
            for order in orders {
                let amount = order.invoice_amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(order.currency, providerID: .once)
                let stamp = order.order_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = order.invoice_number
                    ?? order.order_number.map { String(format: "%.0f", $0) }
                    ?? order.order_type
                    ?? "order"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: order.order_type ?? "order",
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
            if orders.count < 10 { break }
            page += 1
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .once
        )
        return Snapshot(
            providerID: .once,
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

    private func accessToken(credential: Credential) async throws -> String {
        if let ready = credential.value(for: .apiToken)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !ready.isEmpty
        {
            return ready
        }
        let clientID = try RequiredCredential.value(.clientID, in: credential, providerID: .once)
        let clientSecret = try RequiredCredential.value(.clientSecret, in: credential, providerID: .once)
        let basic = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()
        let body = try JSONSerialization.data(withJSONObject: ["grant_type": "client_credentials"])
        let url = ProviderURL.https(host: "api.1nce.com", path: "/management-api/oauth/token")
        let data = try await ProviderHTTP.post(
            url: url,
            headers: [
                "Authorization": "Basic \(basic)",
                "Content-Type": "application/json",
                "Accept": "application/json",
            ],
            body: body,
            client: httpClient,
            providerID: .once
        )
        let token = try ProviderHTTP.decode(TokenResponse.self, from: data, providerID: .once)
        guard let access = token.access_token, !access.isEmpty else {
            throw ProviderError.unauthorized(providerID: .once)
        }
        return access
    }

    private func loadOrders(page: Int, headers: [String: String]) async throws -> [Order] {
        let url = ProviderURL.https(
            host: "api.1nce.com",
            path: "/management-api/v1/orders",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "pageSize", value: "10"),
                URLQueryItem(name: "sort", value: "order_date"),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .once
        )
        return try ProviderHTTP.decode([Order].self, from: data, providerID: .once)
    }

    struct TokenResponse: Decodable, Sendable {
        var access_token: String?
        var token_type: String?
        var expires_in: Int?
    }

    struct Order: Decodable, Sendable {
        var order_number: Double?
        var order_type: String?
        var order_date: String?
        var order_status: String?
        var invoice_number: String?
        var invoice_amount: FlexibleDecimal?
        var currency: String?
    }
}
