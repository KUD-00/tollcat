import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PolarBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "polar_oat_MUST-NOT-LEAK"

    @Test("手续费 = 营收 − 净营收，营收本身不进快照")
    func feeIsRevenueMinusNetRevenue() async throws {
        let client = LiveProviderHarness.stub([
            (metricsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("polar-metrics"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        // totals：195000 − 185850 = 9150 分 = $91.50，不是 $1950 的营收。
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "91.5")!))

        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 54))
        #expect(daily[LiveProviderHarness.date(2026, 8, 7)] == Money(usd: Decimal(string: "22.5")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 15)] == Money(usd: 15))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("退款月净营收反超时不写负手续费")
    func refundMonthClampsToZero() {
        let fee = PolarBillingProvider.feeCents(
            revenue: FlexibleDecimal(Decimal(1000)),
            net: FlexibleDecimal(Decimal(1200))
        )
        #expect(fee == 0)
    }

    @Test("缺 totals 时退回逐日相加，不当成 0")
    func totalsFallBackToDailySum() async throws {
        let client = LiveProviderHarness.stub([
            (
                metricsURL,
                LiveProviderHarness.json([
                    "periods": [
                        ["timestamp": "2026-08-03T00:00:00Z", "revenue": 10000, "net_revenue": 9500],
                        ["timestamp": "2026-08-04T00:00:00Z", "revenue": 20000, "net_revenue": 19000],
                    ],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: 15))
    }

    @Test("只请求 revenue 和 net_revenue 两个指标，按天切")
    func requestsOnlyWhatItNeeds() {
        let query = metricsURL.query ?? ""
        #expect(query.contains("interval=day"))
        #expect(query.contains("metrics=revenue"))
        #expect(query.contains("metrics=net_revenue"))
        #expect(query.contains("start_date=2026-08-01"))
        #expect(query.contains("end_date=2026-08-31"))
    }

    private var metricsURL: URL {
        PolarBillingProvider.metricsURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .polar, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> PolarBillingProvider {
        PolarBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
