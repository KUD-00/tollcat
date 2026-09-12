import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ElevenLabsBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "el-MUST-NOT-LEAK"

    @Test("额度内按免费额度比例")
    func freeTierRatio() async throws {
        let client = LiveProviderHarness.stub([
            (ElevenLabsBillingProvider.subscriptionURL, LiveProviderHarness.body(LiveProviderHarness.fixture("elevenlabs-subscription"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.freeQuotaUsedRatio == 0.25)
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("有超量按 usage")
    func overageIsUsage() async throws {
        let client = LiveProviderHarness.stub([
            (ElevenLabsBillingProvider.subscriptionURL, LiveProviderHarness.json([
                "character_count": 12000,
                "character_limit": 10000,
                "currency": "usd",
                "current_overage": ["amount": "4.20", "currency": "usd"],
            ])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 4.20))
    }

    @Test("超量币种不是 USD 拒绝")
    func rejectsNonUSDOverage() async {
        let client = LiveProviderHarness.stub([
            (ElevenLabsBillingProvider.subscriptionURL, LiveProviderHarness.json([
                "character_count": 1,
                "character_limit": 10,
                "current_overage": ["amount": "1", "currency": "eur"],
            ])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    private var credential: Credential {
        Credential(providerID: .elevenlabs, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ElevenLabsBillingProvider {
        ElevenLabsBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }
}
