import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Pleo 买方平台费（`POST /v1/accounting-entries:search`，仅 `families=["PLEO_INVOICE"]`）。
///
/// 文档：https://developers.pleo.io/reference/accounting-entries/v1/search-accounting-entries
/// 认证：HTTP Basic，用户名为 Standalone API Key、密码为空（需 `accounting-entries:read`）。
/// Host：`external.pleo.io`。Query：`company_id`（UUID）必填。
/// 金额：`transactionValue.minors` + `transactionValue.currency`（ISO 4217；零小数币不除 100）。
/// 跳过 `CANCELLED` / `REJECTED` / `DRAFT` / `ERROR`；`PLEO_INVOICE_REFUND` 记负值。
/// **不用**卡消费 / 报销 / `BILL_INVOICE` 等支出聚合字段——那些不是 Pleo 对本账号的 SaaS 账单。
public struct PleoBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.pleo }
    public static let apiHost = "external.pleo.io"
    static let pageSize = 100
    static let maxPages = 40

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
        let apiKey: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .pleo) {
            apiKey = primary
        } else if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .pleo) {
            apiKey = primary
        } else {
            apiKey = try RequiredCredential.value(.personalAccessToken, in: credential, providerID: .pleo)
        }
        let companyID = try RequiredCredential.value(.accountID, in: credential, providerID: .pleo)
        let headers = [
            "Authorization": "Basic \(ProviderOAuth.basicValue(id: apiKey, secret: ""))",
            "Accept": "application/json;charset=UTF-8",
            "Content-Type": "application/json;charset=UTF-8",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        var after: String? = nil
        var pages = 0
        while pages < Self.maxPages {
            pages += 1
            let page = try await loadPage(companyID: companyID, after: after, headers: headers)
            let batch = page.data ?? []
            if batch.isEmpty { break }
            for entry in batch {
                let status = (entry.status ?? "").uppercased()
                if Self.skipStatuses.contains(status) { continue }
                guard let money = entry.transactionValue ?? entry.totalBillValue else { continue }
                let currency = money.currency?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                guard let currency, !currency.isEmpty else { continue }
                let minors = money.minors?.value ?? 0
                guard minors != 0 else { continue }
                var amount = Self.majorUnits(minors, currency: currency)
                let sub = (entry.subFamily ?? "").uppercased()
                if sub == "PLEO_INVOICE_REFUND" || amount < 0 {
                    amount = -abs(amount)
                } else {
                    amount = abs(amount)
                }
                try currencies.observe(currency, providerID: .pleo)
                let stamp = entry.performedAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? entry.settledAt.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? entry.bookkeepingDate.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? current.start
                let label = entry.id ?? "pleo-invoice"
                if current.contains(stamp) {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                    lines.add(
                        SpendLine(
                            category: entry.family ?? "PLEO_INVOICE",
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
            guard page.pagination?.hasNextPage == true,
                  let cursor = page.pagination?.endCursor,
                  !cursor.isEmpty,
                  cursor != after
            else { break }
            after = cursor
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .pleo
        )
        return Snapshot(
            providerID: .pleo,
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

    static let skipStatuses: Set<String> = [
        "CANCELLED", "CANCELED", "REJECTED", "DRAFT", "ERROR",
    ]

    /// Pleo `Money.minors` 为最小货币单位；零小数币不除 100。
    static func majorUnits(_ minor: Decimal, currency: String) -> Decimal {
        let zeroDecimal: Set<String> = ["JPY", "KRW", "VND", "CLP", "ISK", "UGX", "XAF", "XOF", "XPF"]
        if zeroDecimal.contains(currency.uppercased()) { return minor }
        return minor / 100
    }

    static func searchURL(companyID: String, after: String?) -> URL {
        var query = [
            URLQueryItem(name: "company_id", value: companyID),
            URLQueryItem(name: "limit", value: String(pageSize)),
        ]
        if let after, !after.isEmpty {
            query.append(URLQueryItem(name: "after", value: after))
        }
        return ProviderURL.https(host: apiHost, path: "/v1/accounting-entries:search", query: query)
    }

    private func loadPage(
        companyID: String,
        after: String?,
        headers: [String: String]
    ) async throws -> Page {
        let body = try JSONSerialization.data(
            withJSONObject: [
                "includeDeleted": false,
                "families": ["PLEO_INVOICE"],
            ] as [String: Any]
        )
        let data = try await ProviderHTTP.post(
            url: Self.searchURL(companyID: companyID, after: after),
            headers: headers,
            body: body,
            client: httpClient,
            providerID: .pleo
        )
        return try ProviderHTTP.decode(Page.self, from: data, providerID: .pleo)
    }

    struct Page: Decodable, Sendable {
        var data: [Entry]?
        var pagination: Pagination?
    }

    struct Pagination: Decodable, Sendable {
        var hasNextPage: Bool?
        var endCursor: String?
    }

    struct Entry: Decodable, Sendable {
        var id: String?
        var family: String?
        var subFamily: String?
        var status: String?
        var performedAt: String?
        var settledAt: String?
        var bookkeepingDate: String?
        var transactionValue: MoneyValue?
        var totalBillValue: MoneyValue?
    }

    struct MoneyValue: Decodable, Sendable {
        var currency: String?
        var minors: FlexibleDecimal?
    }
}
