import Foundation
import MeterCore

/// Hugging Face 本月计算花费。
///
/// 文档：个人 `GET /api/settings/billing/usage-v2`；组织
/// `GET /api/organizations/{name}/billing/usage-v2`。
/// 认证：`Authorization: Bearer <token>`。
///
/// `startDate` / `endDate` 必须是本月 1 号和下月 1 号的毫秒时间戳。
/// 金额在各产品行的 `totalCostMicroUSD`，除以 1e6 才是美元。
public struct HuggingFaceBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.huggingface }
    static let microUSDPerUSD = Decimal(1_000_000)

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
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .huggingface)
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let months = CalendarMonthWindow.months(
            for: horizon,
            lookbackMonths: Self.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let org = credential.value(for: .accountID)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var daily = DailySpendAccumulator()
        var currentTotal: Decimal = 0
        for month in months {
            let data: Data
            do {
                data = try await ProviderHTTP.get(
                    url: Self.usageURL(organization: org.isEmpty ? nil : org, window: month),
                    headers: [
                        "Authorization": "Bearer \(token)",
                    ],
                    client: httpClient,
                    providerID: .huggingface
                )
            } catch let error as ProviderError where error.code == .billingAPIUnavailable {
                if month.start == current.start { throw error }
                continue
            }
            let payload = try ProviderHTTP.decode(Usage.self, from: data, providerID: .huggingface)
            if month.start == current.start {
                currentTotal = payload.totalUSD
            } else {
                daily.addPastMonth(
                    start: month.start,
                    amount: Money(usd: payload.totalUSD),
                    current: current,
                    calendar: calendar
                )
            }
        }
        return Snapshot(
            providerID: .huggingface,
            kind: .usage,
            fetchedAt: now,
            periodStart: current.start,
            periodEnd: current.endInclusive,
            currentSpendUSD: Money(usd: currentTotal),
            dailyUSD: daily.snapshotDaily
        )
    }

    static func usageURL(organization: String?, window: CalendarMonthWindow) -> URL {
        let start = milliseconds(window.start)
        let end = milliseconds(window.nextStart)
        let query = [
            URLQueryItem(name: "startDate", value: String(start)),
            URLQueryItem(name: "endDate", value: String(end)),
        ]
        if let organization, !organization.isEmpty {
            return ProviderURL.https(
                host: "huggingface.co",
                path: "/api/organizations/\(organization)/billing/usage-v2",
                query: query
            )
        }
        return ProviderURL.https(
            host: "huggingface.co",
            path: "/api/settings/billing/usage-v2",
            query: query
        )
    }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded(.towardZero))
    }

    static func money(microUSD: Decimal) -> Decimal {
        microUSD / microUSDPerUSD
    }

    struct Usage: Decodable, Sendable {
        var totalUSD: Decimal

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicKey.self)
            if let total = try container.decodeIfPresent(FlexibleDecimal.self, forKey: DynamicKey("totalCostMicroUSD")) {
                totalUSD = HuggingFaceBillingProvider.money(microUSD: total.value)
                return
            }
            var sum: Decimal = 0
            if let usage = try? container.decode([String: [Line]].self, forKey: DynamicKey("usage")) {
                for lines in usage.values {
                    sum += lines.reduce(0) { $0 + ($1.totalCostMicroUSD?.value ?? 0) }
                }
            }
            totalUSD = HuggingFaceBillingProvider.money(microUSD: sum)
        }
    }

    struct Line: Decodable, Sendable {
        var totalCostMicroUSD: FlexibleDecimal?
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init(_ stringValue: String) {
            self.stringValue = stringValue
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
