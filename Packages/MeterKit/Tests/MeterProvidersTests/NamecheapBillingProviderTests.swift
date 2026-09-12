import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct NamecheapBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let user = "nc-user"
    private let key = "nc-key-MUST-NOT-LEAK"
    private let ip = "203.0.113.10"

    @Test("AvailableBalance XML 计入")
    func availableBalance() async throws {
        let url = NamecheapBillingProvider.balancesURL(apiUser: user, apiKey: key, clientIP: ip)
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("namecheap-balances", ext: "xml"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "33.25")!))
        // Namecheap 把 ApiKey 放在 query 里，这是对方接口的要求。
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .namecheap, fields: [.accountID: user, .apiKey: key, .clientID: ip])
    }

    private func provider(_ client: any HTTPClient) -> NamecheapBillingProvider {
        NamecheapBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.catalogRates
        )
    }
}
