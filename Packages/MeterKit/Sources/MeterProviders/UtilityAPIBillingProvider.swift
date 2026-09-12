import Foundation
import MeterCore

/// UtilityAPI 公用事业账单（`GET /api/v2/bills`）。
///
/// 文档：https://utilityapi.com/docs/api/bills
/// 认证：`Authorization: Bearer <token>`。
/// Host：`utilityapi.com`。
/// 金额：`base.bill_total_cost`（美元；美国公用事业账单）。日期：`bill_end_date` / `bill_start_date`。
public struct UtilityAPIBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.utilityapi }
    public static let apiHost = "utilityapi.com"

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
        if let primary = try? RequiredCredential.value(.apiToken, in: credential, providerID: .utilityapi) {
            token = primary
        } else {
            token = try RequiredCredential.value(.apiKey, in: credential, providerID: .utilityapi)
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
        ]
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        var currencies = CurrencyAccumulator()
        var daily = DailySpendAccumulator()
        var lines = SpendLineAccumulator()
        var currentTotal: Decimal = 0

        let bills = try await loadBills(headers: headers)
        for bill in bills {
            let amount = bill.base?.bill_total_cost?.value ?? 0
            guard amount != 0 else { continue }
            try currencies.observe("USD", providerID: .utilityapi)
            let stamp = bill.base?.bill_end_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? bill.base?.bill_start_date.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? bill.updated.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                ?? current.start
            let label = bill.uid ?? bill.utility ?? "bill"
            if current.contains(stamp) {
                currentTotal += amount
                daily.add(day: stamp, amount: Money(usd: amount))
                lines.add(
                    SpendLine(
                        category: "bill",
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
            providerID: .utilityapi
        )
        return Snapshot(
            providerID: .utilityapi,
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

    private func loadBills(headers: [String: String]) async throws -> [Bill] {
        let data = try await ProviderHTTP.get(
            url: Self.billsURL,
            headers: headers,
            client: httpClient,
            providerID: .utilityapi
        )
        if let list = try? ProviderHTTP.decode([Bill].self, from: data, providerID: .utilityapi) {
            return list
        }
        let envelope = try ProviderHTTP.decode(BillList.self, from: data, providerID: .utilityapi)
        return envelope.bills ?? envelope.results ?? []
    }

    static let billsURL = ProviderURL.https(host: apiHost, path: "/api/v2/bills")

    struct BillList: Decodable, Sendable {
        var bills: [Bill]?
        var results: [Bill]?
    }

    struct Bill: Decodable, Sendable {
        var uid: String?
        var utility: String?
        var updated: String?
        var base: Base?
    }

    struct Base: Decodable, Sendable {
        var bill_start_date: String?
        var bill_end_date: String?
        var bill_total_cost: FlexibleDecimal?
    }
}
