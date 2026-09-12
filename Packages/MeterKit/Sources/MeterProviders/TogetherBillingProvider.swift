import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterCore

/// Together AI 组织用量花费（`GET /v1/billing/usage`）。
///
/// 文档：https://docs.together.ai/reference/billing-usage
/// 认证：`Authorization: Bearer <API key>`。
/// Host：`api.together.ai`。
/// 金额：窗口 `line_items[].cost`（USD 十进制字符串）；响应 `currency` 固定 USD。
/// 按 `month=YYYY-MM` + `granularity=day` 分页（`after`）。
/// 凭据：`apiKey`/`apiToken`。可选 `accountID`=`organization_id`。
public struct TogetherBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.together }
    public static let apiHost = "api.together.ai"
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
        let key: String
        if let primary = try? RequiredCredential.value(.apiKey, in: credential, providerID: .together) {
            key = primary
        } else {
            key = try RequiredCredential.value(.apiToken, in: credential, providerID: .together)
        }
        var headers = [
            "Authorization": "Bearer \(key)",
            "Accept": "application/json",
        ]
        let orgID = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
            now: now,
            calendar: calendar
        )
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for month in months {
            let ym = Self.yearMonth(month.start, calendar: calendar)
            var after: String?
            var pages = 0
            repeat {
                pages += 1
                let report = try await loadUsage(
                    month: ym,
                    organizationID: orgID,
                    after: after,
                    headers: headers
                )
                let currency = (report.currency ?? "USD")
                    .trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                try currencies.observe(currency.isEmpty ? "USD" : currency, providerID: .together)
                for window in report.data ?? [] {
                    let day = window.date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? window.start_time.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                        ?? month.start
                    for item in window.line_items ?? [] {
                        let amount = item.cost?.value ?? 0
                        guard amount != 0 else { continue }
                        if current.contains(day) {
                            currentTotal += amount
                            daily.add(day: day, amount: Money(usd: amount))
                            lines.add(
                                SpendLine(
                                    category: "usage",
                                    label: item.product_name ?? "usage",
                                    amountUSD: Money(usd: amount)
                                )
                            )
                        } else if horizon == .availableHistory {
                            daily.addPastMonth(
                                start: day,
                                amount: Money(usd: amount),
                                current: current,
                                calendar: calendar
                            )
                        }
                    }
                }
                after = report.next_cursor
                guard let after, !after.isEmpty else { break }
            } while pages < Self.maxPages
        }

        let converted = try currencies.convert(
            currentTotal,
            rates: rateSource.current,
            providerID: .together
        )
        return Snapshot(
            providerID: .together,
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

    private func loadUsage(
        month: String,
        organizationID: String?,
        after: String?,
        headers: [String: String]
    ) async throws -> Report {
        var query = [
            URLQueryItem(name: "month", value: month),
            URLQueryItem(name: "granularity", value: "day"),
            URLQueryItem(name: "limit", value: "100"),
        ]
        if let organizationID, !organizationID.isEmpty {
            query.append(URLQueryItem(name: "organization_id", value: organizationID))
        }
        if let after, !after.isEmpty {
            query.append(URLQueryItem(name: "after", value: after))
        }
        let data = try await ProviderHTTP.get(
            url: ProviderURL.https(host: Self.apiHost, path: "/v1/billing/usage", query: query),
            headers: headers,
            client: httpClient,
            providerID: .together
        )
        return try ProviderHTTP.decode(Report.self, from: data, providerID: .together)
    }

    static func yearMonth(_ date: Date, calendar: Calendar) -> String {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    struct Report: Decodable, Sendable {
        var currency: String?
        var data: [Window]?
        var next_cursor: String?
    }

    struct Window: Decodable, Sendable {
        var date: String?
        var start_time: String?
        var line_items: [LineItem]?
    }

    struct LineItem: Decodable, Sendable {
        var product_name: String?
        var cost: FlexibleDecimal?
    }
}
