import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TavilyBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "tvly-key-MUST-NOT-LEAK"

    @Test("plan_usage / plan_limit 是额度占比，不报钱")
    func readsQuotaRatio() async throws {
        let client = LiveProviderHarness.stub([
            (TavilyBillingProvider.usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("tavily-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.freeQuotaUsedRatio == 500.0 / 15000.0)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (TavilyBillingProvider.usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("tavily-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("缺 account 是畸形响应")
    func missingAccount() async {
        let client = LiveProviderHarness.stub([
            (TavilyBillingProvider.usageURL, LiveProviderHarness.json(["key": ["usage": 1]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("无限额度 plan_limit=0 占比是 0")
    func unlimitedIsZeroRatio() {
        #expect(TavilyBillingProvider.ratio(used: 10, included: 0) == 0)
    }

    private var credential: Credential {
        Credential(providerID: .tavily, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> TavilyBillingProvider {
        TavilyBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
