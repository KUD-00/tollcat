import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct RevenueCatBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk_MUST-NOT-LEAK"
    private let projectID = "proj1234"

    @Test("按公开费率把 28 天收入折成抽成，收入本身不进快照")
    func derivesFeeFromTrackedRevenue() async throws {
        let client = LiveProviderHarness.stub([
            (overviewURL, LiveProviderHarness.body(LiveProviderHarness.fixture("revenuecat-overview"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        // (9200 − 2500) × 1% = 67.00，不是 9200 的收入。
        #expect(snapshot.currentSpendUSD == Money(usd: 67))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("门槛以内不收钱")
    func belowThresholdIsFree() {
        #expect(RevenueCatFeeSchedule.feeUSD(monthlyTrackedRevenueUSD: 0) == 0)
        #expect(RevenueCatFeeSchedule.feeUSD(monthlyTrackedRevenueUSD: 2_500) == 0)
        #expect(RevenueCatFeeSchedule.feeUSD(monthlyTrackedRevenueUSD: 2_600) == 1)
    }

    @Test("收入指标两个 id 都认")
    func acceptsBothMetricIDs() {
        let legacy = RevenueCatBillingProvider.Overview(metrics: [
            RevenueCatBillingProvider.Metric(
                id: "revenue_last_28_days", name: "Revenue", unit: "$",
                period: "P28D", value: FlexibleDecimal(Decimal(5000))
            ),
        ])
        #expect(RevenueCatBillingProvider.trackedRevenue(legacy) == 5000)
    }

    @Test("非美元的收入指标不认，不做汇率换算")
    func ignoresNonDollarUnit() {
        let euro = RevenueCatBillingProvider.Overview(metrics: [
            RevenueCatBillingProvider.Metric(
                id: "revenue", name: "Revenue", unit: "€",
                period: "P28D", value: FlexibleDecimal(Decimal(5000))
            ),
        ])
        #expect(RevenueCatBillingProvider.trackedRevenue(euro) == nil)
    }

    @Test("没有收入指标时报「没读到」，不是 $0 抽成")
    func missingMetricIsNotZeroFee() async throws {
        let client = LiveProviderHarness.stub([
            (overviewURL, LiveProviderHarness.json(["metrics": []])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    private var overviewURL: URL {
        RevenueCatBillingProvider.overviewURL(projectID: projectID)
    }

    private var credential: Credential {
        Credential(providerID: .revenuecat, fields: [.apiKey: secret, .projectID: projectID])
    }

    private func provider(_ client: any HTTPClient) -> RevenueCatBillingProvider {
        RevenueCatBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
