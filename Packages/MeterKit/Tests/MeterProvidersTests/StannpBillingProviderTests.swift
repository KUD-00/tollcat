import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct StannpBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "stannp-key-MUST-NOT-LEAK"

    @Test("data.balance 字符串美元余额")
    func balanceString() async throws {
        let client = LiveProviderHarness.stub([
            (
                StannpBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("stannp-balance"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD != nil)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .stannp, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> StannpBillingProvider {
        StannpBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
