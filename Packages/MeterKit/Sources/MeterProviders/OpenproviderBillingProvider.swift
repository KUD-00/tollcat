import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Openprovider 发票（`GET /v1beta/invoices`）。
///
/// 文档：https://docs.openprovider.com/doc （InvoiceService）
/// 认证：`POST /v1beta/auth/login` → `data.token`，再 `Authorization: Bearer`。
/// Host：`api.openprovider.eu`。
/// 金额：`amount.reseller.price`（缺省回落 `amount.product.price`）+ currency。
/// 日期：`creation_date`。可用 `start_creation_date` / `end_creation_date` 收窄。
public struct OpenproviderBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.openprovider }
    public static let apiHost = "api.openprovider.eu"

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
        let username: String
        if let primary = try? RequiredCredential.value(.email, in: credential, providerID: .openprovider) {
            username = primary
        } else if let primary = try? RequiredCredential.value(.clientID, in: credential, providerID: .openprovider) {
            username = primary
        } else {
            username = try RequiredCredential.value(.accountID, in: credential, providerID: .openprovider)
        }
        let password: String
        if let primary = try? RequiredCredential.value(.clientSecret, in: credential, providerID: .openprovider) {
            password = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .openprovider) {
            password = primary
        } else {
            password = try RequiredCredential.value(.apiKey, in: credential, providerID: .openprovider)
        }
        let token = try await login(username: username, password: password)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers, current: current, horizon: horizon)
        for inv in invoices {
            let price = inv.amount?.reseller ?? inv.amount?.product
            let amount = price?.price?.value ?? 0
            guard amount != 0 else { continue }
            let currency = price?.currency ?? "EUR"
            try currencies.observe(currency, providerID: .openprovider)
            let stamp = inv.creationDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoiceNumber ?? inv.id.map(String.init) ?? "invoice"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "invoice",
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
            providerID: .openprovider
        )
        return Snapshot(
            providerID: .openprovider,
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

    private func login(username: String, password: String) async throws -> String {
        let body = try JSONSerialization.data(
            withJSONObject: [
                "username": username,
                "password": password,
                "ip": "0.0.0.0",
            ]
        )
        let data = try await ProviderHTTP.post(
            url: Self.loginURL,
            headers: ["Content-Type": "application/json"],
            body: body,
            client: httpClient,
            providerID: .openprovider
        )
        let envelope = try ProviderHTTP.decode(LoginEnvelope.self, from: data, providerID: .openprovider)
        guard let token = envelope.data?.token?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .openprovider)
        }
        return token
    }

    private func loadInvoices(
        headers: [String: String],
        current: CalendarMonthWindow,
        horizon: BillingFetchHorizon
    ) async throws -> [Invoice] {
        let start: Date
        if horizon == .availableHistory {
            let months = CalendarMonthWindow.months(
                for: horizon,
                lookbackMonths: min(Self.descriptor.historyLookbackMonths, 12),
                now: now(),
                calendar: calendar
            )
            start = months.last?.start ?? current.start
        } else {
            start = current.start
        }
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1beta/invoices",
            query: [
                URLQueryItem(name: "limit", value: "100"),
                URLQueryItem(name: "offset", value: "0"),
                URLQueryItem(name: "order_by", value: "creation_date"),
                URLQueryItem(name: "order", value: "desc"),
                URLQueryItem(name: "start_creation_date", value: Self.dateOnly(start)),
                URLQueryItem(name: "end_creation_date", value: Self.dateOnly(current.nextStart)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .openprovider
        )
        let envelope = try ProviderHTTP.decode(InvoiceListEnvelope.self, from: data, providerID: .openprovider)
        return envelope.data?.results ?? []
    }

    static let loginURL = URL(string: "https://api.openprovider.eu/v1beta/auth/login")!

    static func dateOnly(_ date: Date) -> String {
        let c = Calendar(identifier: .gregorian)
        let y = c.component(.year, from: date)
        let m = c.component(.month, from: date)
        let d = c.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    struct LoginEnvelope: Decodable, Sendable {
        var data: LoginData?
    }

    struct LoginData: Decodable, Sendable {
        var token: String?
    }

    struct InvoiceListEnvelope: Decodable, Sendable {
        var data: InvoiceListData?
    }

    struct InvoiceListData: Decodable, Sendable {
        var results: [Invoice]?
        var total: Int?
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var invoiceNumber: String?
        var creationDate: String?
        var amount: Prices?

        enum CodingKeys: String, CodingKey {
            case id
            case invoiceNumber = "invoice_number"
            case creationDate = "creation_date"
            case amount
        }
    }

    struct Prices: Decodable, Sendable {
        var product: Price?
        var reseller: Price?
    }

    struct Price: Decodable, Sendable {
        var currency: String?
        var price: FlexibleDecimal?
    }
}
