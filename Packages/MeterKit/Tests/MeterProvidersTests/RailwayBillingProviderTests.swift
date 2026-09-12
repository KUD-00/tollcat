import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct RailwayBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "railway-token-MUST-NOT-LEAK"
    private let workspace = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

    @Test("customer.currentUsage 就是本周期账单")
    func currentUsageIsTheBill() async throws {
        let client = LiveProviderHarness.stub([
            (RailwayBillingProvider.graphqlURL, LiveProviderHarness.body(LiveProviderHarness.fixture("railway-workspace-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 18.42))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        #expect(client.urls == [RailwayBillingProvider.graphqlURL])
        #expect(client.requests.contains { $0.httpMethod == "POST" })
    }

    @Test("账期结束日是 1 号时按开区间收成上个月最后一天")
    func exclusivePeriodEnd() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let period = BillingPeriodResolver.resolve(
            startRaw: "2026-08-01T00:00:00.000Z",
            endRaw: "2026-09-01T00:00:00.000Z",
            endConvention: .exclusiveWhenMonthStart,
            fallback: window,
            calendar: calendar
        )
        #expect(period.start == LiveProviderHarness.date(2026, 8, 1))
        #expect(period.end == LiveProviderHarness.date(2026, 8, 31))
    }

    @Test("缺 Workspace ID")
    func missingWorkspace() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .railway, fields: [.apiToken: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    @Test("GraphQL 200 但 workspace 为空是畸形响应")
    func emptyWorkspace() async {
        let client = LiveProviderHarness.stub([
            (RailwayBillingProvider.graphqlURL, LiveProviderHarness.json(["data": ["workspace": NSNull()]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .railway, fields: [.apiToken: secret, .accountID: workspace])
    }

    private func provider(_ client: any HTTPClient) -> RailwayBillingProvider {
        RailwayBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
