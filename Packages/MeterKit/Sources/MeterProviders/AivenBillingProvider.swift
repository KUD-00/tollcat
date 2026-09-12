import Foundation
import MeterCore

/// Aiven 本月预估花费。
///
/// 文档：`GET /v1/billing-group`
/// 认证：`Authorization: aivenv1 <personal token>`。
///
/// `estimated_balance_usd` 是计费组本周期税前预估，单位美元。多组相加。
public struct AivenBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.aiven }

    public var httpClient: any HTTPClient
    public var now: @Sendable () -> Date
    public var calendar: Calendar

    public init(httpClient: any HTTPClient, now: @escaping @Sendable () -> Date, calendar: Calendar) {
        self.httpClient = httpClient
        self.now = now
        self.calendar = calendar
    }

    public func fetch(credential: Credential) async throws -> Snapshot {
        let now = now()
        let token = try RequiredCredential.value(.apiToken, in: credential, providerID: .aiven)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let data = try await ProviderHTTP.get(
            url: Self.billingGroupsURL,
            headers: [
                "Authorization": "aivenv1 \(token)",
            ],
            client: httpClient,
            providerID: .aiven
        )
        let payload = try ProviderHTTP.decode(List.self, from: data, providerID: .aiven)
        let groups = payload.billing_groups ?? []
        var total: Decimal = 0
        var seen = false
        for group in groups {
            guard let amount = group.estimated_balance_usd?.value else { continue }
            seen = true
            total += amount
        }
        if !groups.isEmpty, !seen {
            throw ProviderError.malformedResponse(providerID: .aiven)
        }
        return Snapshot(
            providerID: .aiven,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: total)
        )
    }

    static let billingGroupsURL = URL(string: "https://api.aiven.io/v1/billing-group")!

    struct List: Decodable, Sendable {
        var billing_groups: [Group]?
    }

    struct Group: Decodable, Sendable {
        var billing_group_id: String?
        var estimated_balance_usd: FlexibleDecimal?
    }
}
