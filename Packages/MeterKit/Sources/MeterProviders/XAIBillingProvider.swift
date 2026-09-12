import Foundation
import MeterCore

/// xAI Management Billing：优先后付费/发票/用量美元，而非预充值余额。
///
/// 文档：https://docs.x.ai/developers/rest-api-reference/management/billing
/// 认证：Management API Key + `accountID` = team_id；Host `management-api.x.ai`。
/// 优先顺序：
/// 1) `GET .../postpaid/invoice/preview`（本账期，USD cents）
/// 2) `GET .../invoices`（历史发票 total/subtotal/tax，USD cents）
/// 3) `POST .../usage`（`values: usd` + `AGGREGATION_SUM`，日线美元）
public struct XAIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.xai }
    public static let apiHost = "management-api.x.ai"

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
        let apiKey = try RequiredCredential.value(.apiKey, in: credential, providerID: .xai)
        let teamID = try RequiredCredential.value(.accountID, in: credential, providerID: .xai)
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        try currencies.observe("USD", providerID: .xai)
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        // 1) Current-cycle postpaid preview
        if let preview = try? await loadPostpaidPreview(teamID: teamID, headers: headers) {
            let cents = Self.cents(
                preview.coreInvoice?.amountAfterVat
                    ?? preview.coreInvoice?.totalWithCorr?.val
                    ?? preview.coreInvoice?.amountBeforeVat
            )
            if cents != 0 {
                currentTotal = cents / 100
                daily.add(day: current.start, amount: Money(usd: currentTotal))
                for row in preview.coreInvoice?.lines ?? [] {
                    let amount = Self.cents(row.amount) / 100
                    guard amount != 0 else { continue }
                    lines.add(
                        SpendLine(
                            category: row.unitType ?? "usage",
                            label: row.description ?? "line",
                            amountUSD: Money(usd: amount)
                        )
                    )
                }
            }
        }

        // 2) Invoices (current month + optional history)
        let invoices = (try? await loadInvoices(teamID: teamID, headers: headers)) ?? []
        for inv in invoices {
            let status = (inv.invoiceStatus ?? "").uppercased()
            if status == "INVALID" || status == "WILL_NEVER_BE_CHARGED" { continue }
            let amount = Self.cents(inv.total ?? inv.subtotal) / 100
            guard amount != 0 else { continue }
            let stamp = Self.invoiceStamp(inv, calendar: calendar) ?? current.start
            if current.contains(stamp) || Self.isCurrentCycle(inv, current: current) {
                if currentTotal == 0 {
                    currentTotal += amount
                    daily.add(day: stamp, amount: Money(usd: amount))
                }
                for row in inv.lines ?? [] {
                    let lineAmt = Self.cents(row.amount) / 100
                    guard lineAmt != 0 else { continue }
                    lines.add(
                        SpendLine(
                            category: row.unitType ?? "invoice",
                            label: row.description ?? inv.invoiceNumber ?? "invoice",
                            amountUSD: Money(usd: lineAmt)
                        )
                    )
                }
            } else if horizon == .availableHistory {
                daily.addPastMonth(
                    start: stamp,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }

        // 3) Usage analytics USD (fills daily if still empty / supplements)
        if let usageDaily = try? await loadUsageUSD(
            teamID: teamID,
            headers: headers,
            window: horizon == .availableHistory
                ? CalendarMonthWindow.spanning(
                    for: horizon,
                    lookbackMonths: max(Self.descriptor.historyLookbackMonths, 1),
                    now: now,
                    calendar: calendar
                )
                : current
        ) {
            var usageSum: Decimal = 0
            for (day, amount) in usageDaily {
                guard amount != 0 else { continue }
                usageSum += amount
                if current.contains(day) {
                    daily.add(day: day, amount: Money(usd: amount))
                } else if horizon == .availableHistory {
                    daily.addPastMonth(
                        start: day,
                        amount: Money(usd: amount),
                        current: current,
                        calendar: calendar
                    )
                }
            }
            if currentTotal == 0 {
                currentTotal = usageDaily
                    .filter { current.contains($0.key) }
                    .reduce(Decimal(0)) { $0 + $1.value }
            }
        }

        if currentTotal == 0, daily.total(in: current, calendar: calendar) != .zero {
            currentTotal = daily.total(in: current, calendar: calendar).usd
        }

        return try Snapshot(
            providerID: .xai,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily ?? [:],
            lines: lines.snapshot
        ).convertedToUSD(using: currencies, rates: rateSource.current)
    }

    static func cents(_ raw: String?) -> Decimal {
        guard let raw,
              let value = Decimal(string: raw.trimmingCharacters(in: .whitespacesAndNewlines),
                                  locale: Locale(identifier: "en_US_POSIX")) else {
            return 0
        }
        return value
    }

    static func invoiceStamp(_ inv: Invoice, calendar: Calendar) -> Date? {
        if let y = inv.monthly?.billingCycle?.year, let m = inv.monthly?.billingCycle?.month {
            return calendar.date(from: DateComponents(year: y, month: m, day: 1))
        }
        return inv.createTime.flatMap { BillingDateParser.parse($0, calendar: calendar) }
    }

    static func isCurrentCycle(_ inv: Invoice, current: CalendarMonthWindow) -> Bool {
        guard let y = inv.monthly?.billingCycle?.year, let m = inv.monthly?.billingCycle?.month else {
            return false
        }
        let parts = Calendar.current.dateComponents([.year, .month], from: current.start)
        return parts.year == y && parts.month == m
    }

    private func loadPostpaidPreview(teamID: String, headers: [String: String]) async throws -> Preview {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/billing/teams/\(teamID)/postpaid/invoice/preview"
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .xai
        )
        return try ProviderHTTP.decode(Preview.self, from: data, providerID: .xai)
    }

    private func loadInvoices(teamID: String, headers: [String: String]) async throws -> [Invoice] {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/billing/teams/\(teamID)/invoices"
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .xai
        )
        return try ProviderHTTP.decode(InvoiceList.self, from: data, providerID: .xai).invoices ?? []
    }

    private func loadUsageUSD(
        teamID: String,
        headers: [String: String],
        window: CalendarMonthWindow
    ) async throws -> [Date: Decimal] {
        let url = ProviderURL.https(
            host: Self.apiHost,
            path: "/v1/billing/teams/\(teamID)/usage"
        )
        let start = Self.localStamp(window.start)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: window.endInclusive) ?? window.endInclusive
        let bodyObj: [String: Any] = [
            "analyticsRequest": [
                "timeRange": [
                    "startTime": start,
                    "endTime": Self.localStamp(endExclusive),
                    "timezone": "Etc/UTC",
                ],
                "timeUnit": "TIME_UNIT_DAY",
                "values": [
                    ["name": "usd", "aggregation": "AGGREGATION_SUM"],
                ],
                "groupBy": [] as [String],
                "filters": [] as [Any],
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: bodyObj)
        var hdrs = headers
        hdrs["Content-Type"] = "application/json"
        let data = try await ProviderHTTP.post(
            url: url, headers: hdrs, body: body, client: httpClient, providerID: .xai
        )
        let payload = try ProviderHTTP.decode(UsageResponse.self, from: data, providerID: .xai)
        var out: [Date: Decimal] = [:]
        for series in payload.timeSeries ?? [] {
            for point in series.dataPoints ?? [] {
                let day = point.timestamp.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                    ?? window.start
                let value = point.values?.first.map { Decimal($0) } ?? 0
                out[calendar.startOfDay(for: day), default: 0] += value
            }
        }
        return out
    }

    static func localStamp(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d 00:00:00", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    struct Preview: Decodable, Sendable {
        var coreInvoice: CoreInvoice?
        var billingCycle: Cycle?
    }

    struct CoreInvoice: Decodable, Sendable {
        var lines: [Line]?
        var amountBeforeVat: String?
        var amountAfterVat: String?
        var totalWithCorr: Cents?
    }

    struct InvoiceList: Decodable, Sendable {
        var invoices: [Invoice]?
    }

    struct Invoice: Decodable, Sendable {
        var invoiceId: String?
        var invoiceNumber: String?
        var createTime: String?
        var invoiceStatus: String?
        var lines: [Line]?
        var subtotal: String?
        var tax: String?
        var total: String?
        var monthly: Monthly?
    }

    struct Monthly: Decodable, Sendable {
        var billingCycle: Cycle?
    }

    struct Cycle: Decodable, Sendable {
        var year: Int?
        var month: Int?
    }

    struct Line: Decodable, Sendable {
        var description: String?
        var unitType: String?
        var amount: String?
    }

    struct Cents: Decodable, Sendable {
        var val: String?
    }

    struct UsageResponse: Decodable, Sendable {
        var timeSeries: [Series]?
    }

    struct Series: Decodable, Sendable {
        var dataPoints: [Point]?
    }

    struct Point: Decodable, Sendable {
        var timestamp: String?
        var values: [Double]?
    }
}
