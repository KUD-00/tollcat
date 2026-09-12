import Foundation
import MeterCore

/// bunny.net 本月已发生费用。
///
/// 文档：`GET /billing`
/// 认证：`AccessKey: <account API key>`。
///
/// 只用 `ThisMonthCharges`（当月费用）。不读 `Balance` / `AvailableBalance`（预充值余额）。
/// `BillingRecords` 里 `Type == 3`（MonthlyUsage）可作历史月参考，当前周期以 ThisMonthCharges 为准。
public struct BunnyBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.bunny }

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
        let key = try RequiredCredential.value(.apiKey, in: credential, providerID: .bunny)
        let data = try await ProviderHTTP.get(
            url: Self.billingURL,
            headers: [
                "AccessKey": key,
            ],
            client: httpClient,
            providerID: .bunny
        )
        let payload = try ProviderHTTP.decode(Billing.self, from: data, providerID: .bunny)
        guard let charges = payload.ThisMonthCharges?.value else {
            throw ProviderError.malformedResponse(providerID: .bunny)
        }
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        if horizon == .availableHistory {
            for record in payload.BillingRecords ?? [] {
                // 3 = MonthlyUsage
                guard record.recordType == 3, let amount = record.Amount?.value, amount != 0 else { continue }
                let start = record.Timestamp.flatMap { BillingDateParser.parse($0, calendar: calendar) }
                guard let start else { continue }
                daily.addPastMonth(
                    start: start,
                    amount: Money(usd: amount),
                    current: window,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .bunny,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: charges),
            dailyUSD: daily.snapshotDaily
        )
    }

    static let billingURL = URL(string: "https://api.bunny.net/billing")!

    struct Billing: Decodable, Sendable {
        var ThisMonthCharges: FlexibleDecimal?
        var BillingRecords: [BillingRecord]?
        // Balance / AvailableBalance intentionally ignored (prepaid).
    }

    struct BillingRecord: Decodable, Sendable {
        var Amount: FlexibleDecimal?
        var Timestamp: String?
        var recordType: Int?

        enum CodingKeys: String, CodingKey {
            case Amount, Timestamp
            case recordType = "Type"
        }
    }
}
