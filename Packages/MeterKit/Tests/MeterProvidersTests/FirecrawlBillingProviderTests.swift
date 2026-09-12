import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FirecrawlBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "fc-key-MUST-NOT-LEAK"

    @Test("remaining / plan 是额度占比，不报钱")
    func readsQuotaRatio() async throws {
        let client = LiveProviderHarness.stub([
            (FirecrawlBillingProvider.creditUsageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("firecrawl-credit-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.freeQuotaUsedRatio == 499000.0 / 500000.0)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (FirecrawlBillingProvider.creditUsageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("firecrawl-credit-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("缺 data 是畸形响应")
    func missingData() async {
        let client = LiveProviderHarness.stub([
            (FirecrawlBillingProvider.creditUsageURL, LiveProviderHarness.json(["success": true])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("无限额度 planCredits=0 占比是 0")
    func unlimitedIsZeroRatio() {
        #expect(FirecrawlBillingProvider.ratio(used: 10, included: 0) == 0)
    }

    private var credential: Credential {
        Credential(providerID: .firecrawl, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> FirecrawlBillingProvider {
        FirecrawlBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
