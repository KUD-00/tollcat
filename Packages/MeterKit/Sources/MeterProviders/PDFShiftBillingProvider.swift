import Foundation
import MeterCore

/// PDFShift 发票列表（`GET /v3/invoices`）。
///
/// 文档：https://docs.pdfshift.io/api-reference/invoices-list
/// 认证：`X-API-Key`。Host：`api.pdfshift.io`。
/// 金额：`amount`（定价与条款均为 USD）+ `created`（Unix 毫秒）。
/// 凭据：`apiKey`/`apiToken`。
public struct PDFShiftBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.pdfshift }
    public static let apiHost = "api.pdfshift.io"

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
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .pdfshift) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiToken, in: credential, providerID: .pdfshift)
        }
        let headers = [
            "X-API-Key": token,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for inv in invoices {
            let amount = inv.amount?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe("USD", providerID: .pdfshift)
            let stamp: Date
            if let ms = inv.created?.value {
                stamp = Date(timeIntervalSince1970: NSDecimalNumber(decimal: ms).doubleValue / 1000)
            } else {
                stamp = current.start
            }
            let label = inv.reference ?? "invoice"
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
            providerID: .pdfshift
        )
        return Snapshot(
            providerID: .pdfshift,
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

    private func loadInvoices(headers: [String: String]) async throws -> [Invoice] {
        let data = try await ProviderHTTP.get(
            url: Self.invoicesURL,
            headers: headers,
            client: httpClient,
            providerID: .pdfshift
        )
        let envelope = try ProviderHTTP.decode(InvoiceEnvelope.self, from: data, providerID: .pdfshift)
        return envelope.invoices?.data ?? []
    }

    static let invoicesURL = ProviderURL.https(host: apiHost, path: "/v3/invoices")

    struct InvoiceEnvelope: Decodable, Sendable {
        var success: Bool?
        var invoices: InvoicePage?
    }

    struct InvoicePage: Decodable, Sendable {
        var data: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var created: FlexibleDecimal?
        var amount: FlexibleDecimal?
        var reference: String?
    }
}
