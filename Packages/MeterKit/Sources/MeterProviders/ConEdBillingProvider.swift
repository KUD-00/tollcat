import Foundation
import MeterCore

/// Con Edison / ORU Share My Data Green Button Connect：
/// `GET /gbc/espi/1_1/resource/Subscription/{id}/UsagePoint/{id}/UsageSummary`
/// → `BillLastPeriod` / `billLastPeriod`（FB_16 Usage Summary with cost）+ ESPI ISO 4217 `currency`
/// （数字码，如 840=USD；金额为货币单位的十万分之一，与 NAESB REQ.21 / PG&E ESPI 同口径）。
///
/// 文档：https://www.coned.com/-/media/files/coned/documents/accountandbilling/share-my-data/onboarding-doc.pdf
/// Host：`api.coned.com`。认证：Bearer access_token。
/// `accountID` = SubscriptionID；`projectID` = UsagePointID。
public struct ConEdBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.coned }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .coned)
        let subscriptionID = try RequiredCredential.value(.accountID, in: credential, providerID: .coned)
        let usagePointID = try RequiredCredential.value(.projectID, in: credential, providerID: .coned)
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/atom+xml, application/xml, text/xml, */*",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let lookback = max(Self.descriptor.historyLookbackMonths, 1)
        let windowStart = horizon == .availableHistory
            ? (calendar.date(byAdding: .month, value: -lookback, to: current.start) ?? current.start)
            : current.start
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let url = ProviderURL.https(
            host: "api.coned.com",
            path: "/gbc/espi/1_1/resource/Subscription/\(subscriptionID)/UsagePoint/\(usagePointID)/UsageSummary",
            query: [
                URLQueryItem(name: "published-min", value: formatter.string(from: windowStart)),
                URLQueryItem(name: "published-max", value: formatter.string(from: now)),
            ]
        )
        let data = try await ProviderHTTP.get(
            url: url, headers: headers, client: httpClient, providerID: .coned
        )
        let xml = String(data: data, encoding: .utf8) ?? ""
        let summaries = Self.parseSummaries(xml)

        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        for summary in summaries {
            guard let raw = summary.billLastPeriod, raw != 0 else { continue }
            let alpha = Self.alphaCurrency(summary.currencyCode)
            try currencies.observe(alpha, providerID: .coned)
            let amount = raw / 100_000
            let stamp = summary.billingStart.map { Date(timeIntervalSince1970: $0) } ?? current.start
            if current.contains(stamp) || Self.overlapsCurrent(summary: summary, current: current) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "usageSummary",
                        label: "billLastPeriod",
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
            providerID: .coned
        )
        return Snapshot(
            providerID: .coned,
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

    static func overlapsCurrent(summary: UsageSummary, current: CalendarMonthWindow) -> Bool {
        guard let start = summary.billingStart else { return false }
        let startDate = Date(timeIntervalSince1970: start)
        let endDate: Date
        if let duration = summary.billingDuration {
            endDate = startDate.addingTimeInterval(TimeInterval(duration))
        } else {
            endDate = startDate
        }
        return startDate <= current.endInclusive && endDate >= current.start
    }

    static func alphaCurrency(_ code: Int?) -> String {
        switch code {
        case 840: return "USD"
        case 978: return "EUR"
        case 826: return "GBP"
        case 392: return "JPY"
        case 124: return "CAD"
        case 36: return "AUD"
        case 756: return "CHF"
        case 156: return "CNY"
        default: return "USD"
        }
    }

    static func parseSummaries(_ xml: String) -> [UsageSummary] {
        var results: [UsageSummary] = []
        // ConEd docs use BillLastPeriod; ESPI XML commonly billLastPeriod — accept both.
        let chunks = xml.components(separatedBy: "<UsageSummary")
        for (idx, chunk) in chunks.enumerated() {
            let hasBill = chunk.contains("billLastPeriod") || chunk.contains("BillLastPeriod")
            if idx == 0, !hasBill { continue }
            let body: String
            if let endRange = chunk.range(of: "</UsageSummary>") {
                body = String(chunk[..<endRange.upperBound])
            } else {
                body = chunk
            }
            let bill = firstDecimal(tag: "billLastPeriod", in: body)
                ?? firstDecimal(tag: "BillLastPeriod", in: body)
            let currency = firstInt(tag: "currency", in: body)
                ?? firstInt(tag: "Currency", in: body)
            let start = firstInt(pathHint: "billingPeriod", tag: "start", in: body)
                ?? firstInt(pathHint: "BillingPeriod", tag: "start", in: body)
            let duration = firstInt(pathHint: "billingPeriod", tag: "duration", in: body)
                ?? firstInt(pathHint: "BillingPeriod", tag: "duration", in: body)
            if bill != nil || currency != nil {
                results.append(
                    UsageSummary(
                        billLastPeriod: bill,
                        currencyCode: currency,
                        billingStart: start.map(TimeInterval.init),
                        billingDuration: duration.map(TimeInterval.init)
                    )
                )
            }
        }
        if results.isEmpty {
            let bill = firstDecimal(tag: "billLastPeriod", in: xml)
                ?? firstDecimal(tag: "BillLastPeriod", in: xml)
            if let bill {
                results.append(
                    UsageSummary(
                        billLastPeriod: bill,
                        currencyCode: firstInt(tag: "currency", in: xml)
                            ?? firstInt(tag: "Currency", in: xml),
                        billingStart: (firstInt(pathHint: "billingPeriod", tag: "start", in: xml)
                            ?? firstInt(pathHint: "BillingPeriod", tag: "start", in: xml))
                            .map(TimeInterval.init),
                        billingDuration: (firstInt(pathHint: "billingPeriod", tag: "duration", in: xml)
                            ?? firstInt(pathHint: "BillingPeriod", tag: "duration", in: xml))
                            .map(TimeInterval.init)
                    )
                )
            }
        }
        return results
    }

    static func firstDecimal(tag: String, in xml: String) -> Decimal? {
        guard let text = firstTag(tag, in: xml)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else { return nil }
        return Decimal(string: text)
    }

    static func firstInt(tag: String, in xml: String) -> Int? {
        guard let text = firstTag(tag, in: xml)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        return Int(text)
    }

    static func firstInt(pathHint: String, tag: String, in xml: String) -> Int? {
        guard let range = xml.range(of: "<\(pathHint)", options: .caseInsensitive) else {
            return firstInt(tag: tag, in: xml)
        }
        let slice = String(xml[range.lowerBound...])
        return firstInt(tag: tag, in: slice)
    }

    static func firstTag(_ tag: String, in xml: String) -> String? {
        let open = "<\(tag)"
        guard let openRange = xml.range(of: open) else { return nil }
        let afterOpen = xml[openRange.upperBound...]
        guard let gt = afterOpen.firstIndex(of: ">") else { return nil }
        let rest = afterOpen[afterOpen.index(after: gt)...]
        let close = "</\(tag)>"
        guard let closeRange = rest.range(of: close) else { return nil }
        return String(rest[..<closeRange.lowerBound])
    }

    struct UsageSummary: Sendable {
        var billLastPeriod: Decimal?
        var currencyCode: Int?
        var billingStart: TimeInterval?
        var billingDuration: TimeInterval?
    }
}
