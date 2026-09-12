import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PhaxioBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "phaxio-key"
    private let secret = "phaxio-secret-MUST-NOT-LEAK"

    @Test("data.balance 美分折美元")
    func balanceCents() async throws {
        let client = LiveProviderHarness.stub([
            (
                PhaxioBillingProvider.statusURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("phaxio-status"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "15.75")!))
        #expect(client.leakedSecrets([key, secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .phaxio, fields: [.apiKey: key, .clientSecret: secret])
    }

    private func provider(_ client: any HTTPClient) -> PhaxioBillingProvider {
        PhaxioBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
