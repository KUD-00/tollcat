import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AivenBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "aiven-token-MUST-NOT-LEAK"

    @Test("estimated_balance_usd 多组相加")
    func sumsEstimatedUSD() async throws {
        let client = LiveProviderHarness.stub([
            (
                AivenBillingProvider.billingGroupsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("aiven-billing-groups"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "15.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 aivenv1，不是 Bearer")
    func usesAivenv1() async throws {
        let client = LiveProviderHarness.stub([
            (
                AivenBillingProvider.billingGroupsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("aiven-billing-groups"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "aivenv1 \(secret)")
    }

    @Test("计费组有了但没有 estimated_balance_usd 是畸形响应")
    func missingEstimate() async {
        let client = LiveProviderHarness.stub([
            (
                AivenBillingProvider.billingGroupsURL,
                LiveProviderHarness.json([
                    "billing_groups": [
                        ["billing_group_id": "g1", "billing_group_name": "prod"],
                    ],
                ])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .aiven, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> AivenBillingProvider {
        AivenBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
