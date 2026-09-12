import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct BasetenBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "baseten-key-MUST-NOT-LEAK"

    @Test("三类 subtotal 相加，日线按 daily.subtotal 累")
    func readsUsageSummary() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("baseten-usage-summary"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.5")!))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 4))
        #expect(daily[LiveProviderHarness.date(2026, 8, 10)] == Money(usd: Decimal(string: "9.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("请求 Bearer，end_date 是下月 1 号")
    func requestsBearerWindow() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("baseten-usage-summary"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        let query = summaryURL.query ?? ""
        #expect(query.contains("start_date="))
        #expect(query.contains("end_date="))
    }

    @Test("三类都空是 $0，不是没读到")
    func emptyUsageIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.json([:] as [String: Any])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    private var summaryURL: URL {
        BasetenBillingProvider.usageSummaryURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
    }

    private var credential: Credential {
        Credential(providerID: .baseten, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> BasetenBillingProvider {
        BasetenBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
