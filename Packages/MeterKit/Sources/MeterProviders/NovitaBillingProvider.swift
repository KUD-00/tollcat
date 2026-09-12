import Foundation
import MeterCore

/// Novita AI 本月账单合计（跳过预充值余额）。
///
/// 文档：`GET /openapi/v1/billing/monthly/bill`
/// 认证：`Authorization: Bearer <API key>`。
///
/// `totalAmount` / `cashPayAmount` 单位是 **1/10000 美元**（`10000` = $1.00）。
public struct NovitaBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.novita }
    static let unitsPerUSD = Decimal(10_000)

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        try await fetch(credential: credential, horizon: .currentMonth)
    }

    public func fetch(
        credential: Credential,
        horizon: BillingFetchHorizon
    ) async throws -> Snapshot {
        let now = now()
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .novita)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let headers = [
            "Authorization": "Bearer \(key)",
        ]
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let cycle = Self.billCycle(month.start, calendar: calendar)
            let data = try await ProviderHTTP.get(
                url: Self.monthlyBillURL(billCycle: cycle),
                headers: headers,
                client: httpClient,
                providerID: .novita
            )
            let payload = try ProviderHTTP.decode(MonthlyBill.self, from: data, providerID: .novita)
            let units = payload.cashPayAmount?.value
                ?? payload.totalAmount?.value
                ?? 0
            let amount = units / Self.unitsPerUSD
            if month.start == current.start {
                currentTotal = amount
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: amount),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .novita,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func billCycle(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    static func monthlyBillURL(billCycle: String) -> URL {
        ProviderURL.https(
            host: "api.novita.ai",
            path: "/openapi/v1/billing/monthly/bill",
            query: [
                URLQueryItem(name: "billCycle", value: billCycle),
            ]
        )
    }

    struct MonthlyBill: Decodable, Sendable {
        var totalAmount: FlexibleDecimal?
        var cashPayAmount: FlexibleDecimal?
        var billCycle: String?
    }
}
