import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GandiBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "gandi-pat-MUST-NOT-LEAK"

    @Test("prepaid.amount 按币种折美元")
    func prepaidConverted() async throws {
        let client = LiveProviderHarness.stub([
            (
                GandiBillingProvider.infoURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("gandi-billing-info"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD != nil)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .gandi, fields: [.personalAccessToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> GandiBillingProvider {
        GandiBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.catalogRates
        )
    }
}
