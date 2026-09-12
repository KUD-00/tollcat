import Foundation
import MeterCore

/// RevenueCat 本月抽成（推算值）。
///
/// 文档：`GET /v2/projects/{project_id}/metrics/overview`
/// 认证：`Authorization: Bearer <secret API key>`，限速 25 次/分钟。
///
/// **这是推算不是账单。** RevenueCat 没有开放「我这个月欠你多少」的接口，
/// overview 只给一个 28 天滚动的毛收入。我们拿它当 MTR，套
/// `RevenueCatFeeSchedule` 的门槛和费率算出抽成。
///
/// 两处会和真实账单差开：滚动 28 天不等于自然月；跨项目的收入要分别取数再相加，
/// 而门槛是按账号算的。收入本身不是花销，不进快照。
public struct RevenueCatBillingProvider: BillingProvider, Sendable {
    public static var descriptor: ProviderDescriptor { ProviderCatalog.revenuecat }

    /// 官方在不同版本里用过两个 id，都认。
    static let revenueMetricIDs = ["revenue", "revenue_last_28_days"]

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
        let secret = try RequiredCredential.value(.apiKey, in: credential, providerID: .revenuecat)
        let projectID = try RequiredCredential.value(.projectID, in: credential, providerID: .revenuecat)

        let data = try await ProviderHTTP.get(
            url: Self.overviewURL(projectID: projectID),
            headers: [
                "Authorization": "Bearer \(secret)",
            ],
            client: httpClient,
            providerID: .revenuecat
        )
        let payload = try ProviderHTTP.decode(Overview.self, from: data, providerID: .revenuecat)
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)

        guard let revenue = Self.trackedRevenue(payload) else {
            // 读到了但没有收入指标，按「这次没读到」处理，不要当成 $0 抽成。
            return Snapshot(
                providerID: .revenuecat,
                kind: .usage,
                fetchedAt: now,
                periodStart: window.start,
                periodEnd: window.endInclusive
            )
        }

        return Snapshot(
            providerID: .revenuecat,
            kind: .usage,
            fetchedAt: now,
            periodStart: window.start,
            periodEnd: window.endInclusive,
            currentSpendUSD: Money(usd: RevenueCatFeeSchedule.feeUSD(monthlyTrackedRevenueUSD: revenue))
        )
    }

    /// 只认标着美元的那条。RevenueCat 支持按其它币种返回，换算不做。
    static func trackedRevenue(_ overview: Overview) -> Decimal? {
        for id in revenueMetricIDs {
            guard let metric = overview.metrics?.first(where: { $0.id == id }) else { continue }
            guard metric.unit == nil || metric.unit == "$" else { continue }
            return metric.value?.value
        }
        return nil
    }

    static func overviewURL(projectID: String) -> URL {
        return ProviderURL.https(host: "api.revenuecat.com", path: "/v2/projects/\(projectID)/metrics/overview")
    }

    struct Overview: Decodable, Sendable {
        var metrics: [Metric]?
    }

    struct Metric: Decodable, Sendable {
        var id: String?
        var name: String?
        var unit: String?
        var period: String?
        var value: FlexibleDecimal?
    }
}
