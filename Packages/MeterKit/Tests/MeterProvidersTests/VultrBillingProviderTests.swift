import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct VultrBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiKey = "VULTRKEY-MUST-NOT-LEAK"

    @Test("当月待扣当合计，余额单独走 balance，行项目摊成日线")
    func readsPendingChargesAndBalance() async throws {
        let snapshot = try await provider(fullStub()).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "18.6")!))
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "12.4")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))

        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "10.6")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 5)] == Money(usd: 6))
        #expect(daily[LiveProviderHarness.date(2026, 8, 12)] == Money(usd: 2))
        #expect(daily.values.reduce(Money.zero, +) == snapshot.currentSpendUSD)
    }

    @Test("密钥只进头，不进 URL")
    func keyNeverLeaksIntoURL() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.leakedSecrets([apiKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("行项目合计和 /v2/account 对不上时以 account 为准，差额落月初")
    func headlineWinsOverLineItems() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        var daily = DailySpendAccumulator()
        daily.add(day: LiveProviderHarness.date(2026, 8, 9), amount: Money(usd: 10))
        let rescaled = try! #require(
            VultrBillingProvider.rescaled(daily, to: 12, window: window)
        )
        #expect(rescaled[LiveProviderHarness.date(2026, 8, 9)] == Money(usd: 10))
        #expect(rescaled[window.start] == Money(usd: 2))
    }

    @Test("跨月的月租按月初记，不落到窗口外")
    func chargesOutsideWindowFoldIntoMonthStart() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let items = [
            VultrBillingProvider.PendingCharge(
                description: "上月结转", product: "Cloud Compute",
                start_date: "2026-07-20T00:00:00+00:00", end_date: nil,
                total: FlexibleDecimal(Decimal(5))
            ),
        ]
        let daily = VultrBillingProvider.accumulate(items: items, window: window, calendar: calendar)
        #expect(daily.daily[window.start] == Money(usd: 5))
        #expect(daily.total == Money(usd: 5))
    }

    @Test("没有 pending charge 时合计是 0 而不是没读到")
    func emptyChargesStillReportZero() async throws {
        let client = LiveProviderHarness.stub([
            (VultrBillingProvider.accountURL, LiveProviderHarness.json(["account": ["balance": 3.0]])),
            (VultrBillingProvider.pendingChargesURL, LiveProviderHarness.json(["pending_charges": []])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.dailyUSD == nil)
        #expect(snapshot.hasBillableMetrics)
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (
                VultrBillingProvider.accountURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("vultr-account"))
            ),
            (
                VultrBillingProvider.pendingChargesURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("vultr-pending-charges"))
            ),
        ])
    }

    private var credential: Credential {
        Credential(providerID: .vultr, fields: [.apiKey: apiKey])
    }

    private func provider(_ client: any HTTPClient) -> VultrBillingProvider {
        VultrBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
