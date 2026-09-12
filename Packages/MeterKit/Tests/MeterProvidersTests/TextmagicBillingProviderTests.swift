import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TextmagicBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let username = "textmagic-user-MUST-NOT-LEAK"
    private let apiKey = "textmagic-key-MUST-NOT-LEAK"
    private let gbpRate = Decimal(string: "1.25")!

    @Test("balance 是账户币种余额，按目录汇率折")
    func readsGbpBalance() async throws {
        let client = LiveProviderHarness.stub([
            (TextmagicBillingProvider.userURL, LiveProviderHarness.body(LiveProviderHarness.fixture("textmagic-user"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "100.00")!))
        #expect(snapshot.converted?.currency == "GBP")
        #expect(client.leakedSecrets([username, apiKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Basic")
    func usesBasic() async throws {
        let client = LiveProviderHarness.stub([
            (TextmagicBillingProvider.userURL, LiveProviderHarness.body(LiveProviderHarness.fixture("textmagic-user"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == TextmagicBillingProvider.basicAuthorization(username: username, apiKey: apiKey)
        )
    }

    @Test("没有 balance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (TextmagicBillingProvider.userURL, LiveProviderHarness.json(["username": "x"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .textmagic, fields: [.clientID: username, .clientSecret: apiKey])
    }

    private func provider(_ client: any HTTPClient) -> TextmagicBillingProvider {
        TextmagicBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["GBP": gbpRate]))
        )
    }
}
