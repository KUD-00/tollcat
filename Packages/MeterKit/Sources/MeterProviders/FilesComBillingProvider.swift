import Foundation
import MeterCore

/// Files.com 账户发票（`GET /api/rest/v1/invoices.json`）。
///
/// 文档：https://developers.files.com/rest/resources/billing/account-line-items/
/// 认证：`X-FilesAPI-Key`。Host：`app.files.com`。
/// 金额：发票级 `amount` + `currency`（主币）；日期：`created_at`。
/// 只取 `type == invoice`（同资源也可列 payments）。
/// 行内 `prepaid_bytes*` 是用量字段，不是预付钱包——金额仍读发票级 `amount`。
public struct FilesComBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.filescom }
    public static let apiHost = "app.files.com"
    static let maxPages = 20

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
        let key: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .filescom) {
            key = primary
        } else {
            key = try RequiredCredential.value(.apiToken, in: credential, providerID: .filescom)
        }
        let headers = [
            "X-FilesAPI-Key": key,
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var cursor: String? = nil
        var page = 0
        while page < Self.maxPages {
            page += 1
            let (invoices, next) = try await loadInvoices(cursor: cursor, headers: headers)
            for inv in invoices {
                let kind = (inv.type ?? "").lowercased()
                if !kind.isEmpty && kind != "invoice" { continue }
                let amount = inv.amount?.value ?? 0
                guard amount != 0 else { continue }
                try currencies.observe(inv.currency, providerID: .filescom)
                let stamp = inv.created_at.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = inv.id.map(String.init) ?? "invoice"
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
            guard let next, !next.isEmpty, !invoices.isEmpty else { break }
            cursor = next
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .filescom
        )
        return Snapshot(
            providerID: .filescom,
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

    private func loadInvoices(
        cursor: String?,
        headers: [String: String]
    ) async throws -> ([Invoice], String?) {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: "100"),
        ]
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/api/rest/v1/invoices.json",
            query: query
        )
        let (data, response) = try await ProviderHTTP.getResponse(
            url: url,
            headers: headers,
            client: httpClient,
            providerID: .filescom
        )
        let invoices = try ProviderHTTP.decode([Invoice].self, from: data, providerID: .filescom)
        let next = response.value(forHTTPHeaderField: "X-Files-Cursor-Next")
        return (invoices, next)
    }

    static var invoicesURL: URL {
        ProviderURL.https(host: apiHost, path: "/api/rest/v1/invoices.json")
    }

    struct Invoice: Decodable, Sendable {
        var id: Int?
        var amount: FlexibleDecimal?
        var currency: String?
        var created_at: String?
        var type: String?
    }
}
