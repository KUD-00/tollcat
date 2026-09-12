import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PorkbunBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "porkbun-key"
    private let secret = "porkbun-secret-MUST-NOT-LEAK"

    @Test("balance 美分折美元")
    func balanceCents() async throws {
        let client = LiveProviderHarness.stub([
            (
                PorkbunBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("porkbun-balance"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "25")!))
        #expect(client.leakedSecrets([key, secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .porkbun, fields: [.apiKey: key, .clientSecret: secret])
    }

    private func provider(_ client: any HTTPClient) -> PorkbunBillingProvider {
        PorkbunBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
