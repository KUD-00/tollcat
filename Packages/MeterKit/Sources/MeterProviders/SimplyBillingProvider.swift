import Foundation
import MeterCore

/// Simply.com 本月已付发票合计。
///
/// 文档：`GET https://api.simply.com/2/my/invoices/` → `invoices[].amount` + `currency`（ISO）。
/// 认证：`Authorization: Bearer <API key>`（或 Basic，任意用户名 + API key）。
public struct SimplyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.simply }

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .simply)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let invoices = try await loadInvoices(headers: headers)
        for invoice in invoices {
            try currencies.observe(invoice.currency, providerID: .simply)
            let amount = invoice.amount?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = invoice.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            if current.contains(stamp) {
                currentTotal += amount
                let label = invoice.subject?.trimmed
                    ?? invoice.reference?.trimmed
                    ?? invoice.invoiceno?.trimmed
                    ?? "invoice"
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

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .simply)
        return Snapshot(
            providerID: .simply,
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
            url: Self.listURL,
            headers: headers,
            client: httpClient,
            providerID: .simply
        )
        let envelope = try ProviderHTTP.decode(Envelope.self, from: data, providerID: .simply)
        return envelope.invoices ?? []
    }

    static let listURL = ProviderURL.https(
        host: "api.simply.com",
        path: "/2/my/invoices/"
    )

    struct Envelope: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var date: String?
        var invoiceno: String?
        var reference: String?
        var subject: String?
        var amount: FlexibleDecimal?
        var currency: String?
        var transactionno: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
