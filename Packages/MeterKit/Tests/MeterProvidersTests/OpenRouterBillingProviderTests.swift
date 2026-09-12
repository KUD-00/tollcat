import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct OpenRouterBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-or-mgmt-MUST-NOT-LEAK"

    @Test("Management key 读到剩余额度")
    func remainingCredits() async throws {
        let client = LiveProviderHarness.stub([
            (OpenRouterBillingProvider.creditsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("openrouter-credits"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.providerID == .openrouter)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(roundedUSD: 74.75))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("已用超过已购按 $0 余额")
    func usageExceedsCredits() async throws {
        let client = LiveProviderHarness.stub([
            (OpenRouterBillingProvider.creditsURL, LiveProviderHarness.json([
                "data": ["total_credits": 10, "total_usage": 12],
            ])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == .zero)
    }

    @Test("缺少字段是畸形响应")
    func missingFields() async {
        let client = LiveProviderHarness.stub([
            (OpenRouterBillingProvider.creditsURL, LiveProviderHarness.json(["data": [:] as [String: Any]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("401 / 403")
    func statusMapping() async {
        for (status, code, key) in [
            (401, ProviderError.Code.unauthorized, RemediationKey.invalidCredentials),
            (403, ProviderError.Code.forbidden, RemediationKey.insufficientPermissions),
        ] {
            let client = LiveProviderHarness.stub([
                (OpenRouterBillingProvider.creditsURL, LiveProviderHarness.emptyJSON(status: status)),
            ])
            let error = await #expect(throws: ProviderError.self) {
                try await provider(client).fetch(credential: credential)
            }
            #expect(error?.code == code)
            #expect(error?.remediationKey == key)
        }
    }

    @Test("缺少 Management key")
    func missingKey() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .openrouter, fields: [:])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var credential: Credential {
        Credential(providerID: .openrouter, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> OpenRouterBillingProvider {
        OpenRouterBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
