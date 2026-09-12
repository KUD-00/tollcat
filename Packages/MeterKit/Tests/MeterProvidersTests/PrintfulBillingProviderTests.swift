import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PrintfulBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "printful-token-MUST-NOT-LEAK"

    @Test("本月 orders costs.total 合计")
    func sumsOrderCosts() async throws {
        let url = PrintfulBillingProvider.ordersURL(offset: 0)
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("printful-orders"))),
        ])
        let snapshot = try await PrintfulBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        ).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "50.00")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .printful, fields: [.apiKey: secret])
    }
}
