import Foundation
import MeterCore

/// Active24 本月发票合计（`price` + `currency`，`issueDate`）。
///
/// 文档：
/// - `GET /payments/v1` → `RestPaymentItemData`（price / currency / issueDate / variableSymbol）
/// - `GET /payments/invoice/{variableSymbol}/v1` → 行项目（可选明细）
/// 认证：`Authorization: Bearer <Auth Token>`。
/// 跳过 `CANCELED`；优先本月 `issueDate`。
public struct Active24BillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.active24 }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .active24)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let payments = try await loadPayments(headers: headers)
        var currentSymbols: [String] = []
        for payment in payments {
            let status = payment.status?.uppercased() ?? ""
            guard status != "CANCELED" else { continue }
            try currencies.observe(payment.currency, providerID: .active24)
            let amount = payment.price?.value ?? 0
            guard amount != 0 else { continue }
            let stamp = payment.issueDate?.date ?? current.start
            if current.contains(stamp) {
                currentTotal += amount
                if let vs = payment.variableSymbol?.trimmed {
                    currentSymbols.append(vs)
                }
                let label = payment.subjectConcated?.trimmed
                    ?? payment.variableSymbol?.trimmed
                    ?? "invoice"
                lines.add(
                    SpendLine(
                        category: status.isEmpty ? "invoice" : status.lowercased(),
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

        // Prefer invoice line items for current-month symbols when available.
        if !currentSymbols.isEmpty {
            var detailLines = SpendLineAccumulator()
            var gotDetail = false
            for vs in currentSymbols.prefix(20) {
                guard let rows = try? await loadInvoice(variableSymbol: vs, headers: headers) else { continue }
                for row in rows {
                    let amount = row.price?.value ?? 0
                    guard amount != 0 else { continue }
                    gotDetail = true
                    try? currencies.observe(row.currency, providerID: .active24)
                    let label = row.description?.trimmed
                        ?? row.domain?.trimmed
                        ?? row.vs?.trimmed
                        ?? "item"
                    detailLines.add(
                        SpendLine(
                            category: row.domain?.trimmed ?? "service",
                            label: label,
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
            if gotDetail {
                lines = detailLines
            }
        }

        let converted = try currencies.convert(currentTotal, rates: rateSource.current, providerID: .active24)
        return Snapshot(
            providerID: .active24,
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

    private func loadPayments(headers: [String: String]) async throws -> [Payment] {
        let data = try await ProviderHTTP.get(
            url: Self.paymentsURL,
            headers: headers,
            client: httpClient,
            providerID: .active24
        )
        return try ProviderHTTP.decode([Payment].self, from: data, providerID: .active24)
    }

    private func loadInvoice(variableSymbol: String, headers: [String: String]) async throws -> [InvoiceRow] {
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(
                host: "api.active24.com",
                path: "/payments/invoice/\(variableSymbol)/v1"
            ),
            headers: headers,
            client: httpClient,
            providerID: .active24
        )
        return try ProviderHTTP.decode([InvoiceRow].self, from: data, providerID: .active24)
    }

    static let paymentsURL = ProviderURL.https(host: "api.active24.com", path: "/payments/v1")


    struct FlexibleIssueStamp: Decodable, Sendable {
        var date: Date?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let number = try? container.decode(Double.self) {
                if number > 1_000_000_000_000 {
                    date = Date(timeIntervalSince1970: number / 1000)
                } else if number > 1_000_000_000 {
                    date = Date(timeIntervalSince1970: number)
                }
                return
            }
            if let int = try? container.decode(Int64.self) {
                let number = Double(int)
                if number > 1_000_000_000_000 {
                    date = Date(timeIntervalSince1970: number / 1000)
                } else if number > 1_000_000_000 {
                    date = Date(timeIntervalSince1970: number)
                }
                return
            }
            if let string = try? container.decode(String.self) {
                if let millis = Double(string), millis > 1_000_000_000_000 {
                    date = Date(timeIntervalSince1970: millis / 1000)
                    return
                }
                date = BillingDateParser.parse(string, calendar: Calendar(identifier: .gregorian))
            }
        }
    }

    struct Payment: Decodable, Sendable {
        var currency: String?
        var detailKey: String?
        var issueDate: FlexibleIssueStamp?
        var price: FlexibleDecimal?
        var status: String?
        var subjectConcated: String?
        var variableSymbol: String?
        var invoice: InvoiceMeta?
    }

    struct InvoiceMeta: Decodable, Sendable {
        var creditNote: Bool?
        var documentUrl: String?
        var invoiceIdentifier: String?
    }

    struct InvoiceRow: Decodable, Sendable {
        var currency: String?
        var description: String?
        var domain: String?
        var price: FlexibleDecimal?
        var status: String?
        var vs: String?
    }
}

private extension String {
    var trimmed: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
