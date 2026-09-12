import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Scalingo 账户发票（`GET /v1/account/invoices`）。
///
/// 文档：https://developers.scalingo.com/invoices
/// 认证：长效 API token → `POST https://auth.scalingo.com/v1/tokens/exchange` 换 Bearer（Basic `:<token>`）。
/// Host：`api.osc-fr1.scalingo.com`（账单随账户，区域宿主取官方默认 Paris）。
/// 金额：`total_price_with_vat`（欧分）；官方消费导出亦为 Euro cents。日期 `billing_month`。
/// 跳过 `failed`。凭据：`apiToken`/`apiKey`。
public struct ScalingoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.scalingo }
    public static let apiHost = "api.osc-fr1.scalingo.com"
    public static let authHost = "auth.scalingo.com"
    public static let centsPerUnit = Decimal(100)

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .scalingo) {
            apiToken = primary
        } else {
            apiToken = try RequiredCredential.value(.apiKey, in: credential, providerID: .scalingo)
        }
        let bearer = try await exchangeBearer(apiToken: apiToken)
        let headers = [
            "Authorization": "Bearer \(bearer)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            let status = (inv.state ?? "").lowercased()
            if status == "failed" { continue }
            let cents = inv.total_price_with_vat?.value ?? inv.total_price?.value ?? 0
            let amount = cents / Self.centsPerUnit
            guard amount != 0 else { continue }
            try currencies.observe("EUR", providerID: .scalingo)
            let stamp = inv.billing_month.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = inv.invoice_number ?? inv.id ?? "invoice"
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
            providerID: .scalingo
        )
        return Snapshot(
            providerID: .scalingo,
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

    private func exchangeBearer(apiToken: String) async throws -> String {
        let basic = ProviderOAuth.basicValue(id: "", secret: apiToken)
        let data = try await ProviderHTTP.post(
            url: Self.exchangeURL,
            headers: [
                "Authorization": "Basic \(basic)",
                "Accept": "application/json",
                "Content-Type": "application/json",
            ],
            body: Data("{}".utf8),
            client: httpClient,
            providerID: .scalingo
        )
        let payload = try ProviderHTTP.decode(Exchange.self, from: data, providerID: .scalingo)
        guard let token = payload.token?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: .scalingo)
        }
        return token
    }

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: headers,
            client: httpClient,
            providerID: .scalingo
        )
        let envelope = try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .scalingo)
        return envelope.invoices ?? []
    }

    public static let exchangeURL = ProviderURL.https(host: authHost, path: "/v1/tokens/exchange")
    public static let invoicesURL = ProviderURL.https(host: apiHost, path: "/v1/account/invoices")

    struct Exchange: Decodable, Sendable {
        var token: String?
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var id: String?
        var total_price: FlexibleDecimal?
        var total_price_with_vat: FlexibleDecimal?
        var billing_month: String?
        var invoice_number: String?
        var state: String?
    }
}
