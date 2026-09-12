import Foundation
import MeterCore

/// IONOS Cloud 当月发票合计。
///
/// 文档：`GET /billing/invoices/{YYYY-MM}`
/// 认证：DCD Token Manager 签发的 JWT，`Authorization: Bearer`。
///
/// `total.quantity` 是该合同该月发票金额，`total.unit` 常见欧元。
/// IONOS 月末出账，当月那张**不一定已经存在**。404 或空列表返回一条没有读数的
/// 快照（不是 $0），交给上层显示「这次没读到」。
///
/// 用量接口只给小时，不拿价目自己乘。
public struct IONOSCloudBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.ionos }

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .ionos)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        var currency = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal?
        var currentUnread = false
        for month in months {
            let loaded = try await loadMonth(month, token: token, currency: &currency)
            switch loaded {
            case .unread:
                if month.start == current.start { currentUnread = true }
            case .amount(let total):
                if month.start == current.start {
                    currentTotal = total
                } else {
                    daily.addPastMonth(
                        start: month.start,
                        amount: Money(usd: total),
                        current: current,
                        calendar: calendar
                    )
                }
            }
        }
        if currentUnread, currentTotal == nil {
            var snapshot = Self.unread(now: now, window: current)
            snapshot.dailyUSD = daily.snapshotDaily
            return snapshot
        }
        guard let currentTotal else {
            throw ProviderError.malformedResponse(providerID: .ionos)
        }
        return try Snapshot(
            providerID: .ionos,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        ).convertedToUSD(using: currency, rates: rateSource.current)
    }

    private enum MonthLoad: Sendable {
        case unread
        case amount(Decimal)
    }

    private func loadMonth(
        _ month: CalendarMonthWindow,
        token: String,
        currency: inout CurrencyAccumulator
    ) async throws -> MonthLoad {
        let data: Data
        do {
            data = try await ProviderHTTP.get(
                url: Self.invoicesURL(window: month, calendar: calendar),
                headers: [
                    "Authorization": "Bearer \(token)",
                ],
                client: httpClient,
                providerID: .ionos
            )
        } catch let error as ProviderError where error.code == .billingAPIUnavailable {
            return .unread
        }
        let invoices = try ProviderHTTP.decode([Invoice].self, from: data, providerID: .ionos)
        guard !invoices.isEmpty else { return .unread }
        var total: Decimal = 0
        var seen = false
        for invoice in invoices {
            guard let amount = invoice.total?.quantity?.value else { continue }
            try currency.observe(invoice.total?.unit, providerID: .ionos)
            total += amount
            seen = true
        }
        if !seen {
            throw ProviderError.malformedResponse(providerID: .ionos)
        }
        return .amount(total)
    }

    static func unread(now: Date, window: CalendarMonthWindow) -> Snapshot {
        Snapshot(
            providerID: .ionos,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive
        )
    }

    static func invoicesURL(window: CalendarMonthWindow, calendar: Calendar) -> URL {
        ProviderURL.https(
            host: "api.ionos.com",
            path: "/billing/invoices/\(period(window: window, calendar: calendar))"
        )
    }

    static func period(window: CalendarMonthWindow, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: window.start)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    struct Invoice: Decodable, Sendable {
        var metadata: Metadata?
        var total: Amount?
    }

    struct Metadata: Decodable, Sendable {
        var invoiceId: String?
        var postingPeriod: String?
        var startDate: String?
        var endDate: String?
        var finallyPosted: Bool?
    }

    struct Amount: Decodable, Sendable {
        var quantity: FlexibleDecimal?
        var unit: String?
    }
}
