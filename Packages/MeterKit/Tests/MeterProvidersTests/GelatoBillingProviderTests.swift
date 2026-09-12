import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GelatoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "gelato-key-MUST-NOT-LEAK"

    @Test("本月 purchase 计入、refund 冲减")
    func sumsReceipts() async throws {
        let client = LiveProviderHarness.stub([
            (
                GelatoBillingProvider.searchURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("gelato-search"))
            ),
            (
                GelatoBillingProvider.orderURL(id: "ord_1"),
                LiveProviderHarness.body(LiveProviderHarness.fixture("gelato-order"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .gelato, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> GelatoBillingProvider {
        GelatoBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
