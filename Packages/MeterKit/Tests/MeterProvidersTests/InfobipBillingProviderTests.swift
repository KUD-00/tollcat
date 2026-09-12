import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct InfobipBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiKey = "infobip-key-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("balance 是账户币种余额，按目录汇率折")
    func readsEuroBalance() async throws {
        let client = LiveProviderHarness.stub([
            (InfobipBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("infobip-balance"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "11.00")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([apiKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 App 头")
    func usesAppAuthorization() async throws {
        let client = LiveProviderHarness.stub([
            (InfobipBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("infobip-balance"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "App \(apiKey)")
    }

    @Test("没有 balance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (InfobipBillingProvider.balanceURL, LiveProviderHarness.json(["currency": "EUR"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .infobip, fields: [.apiKey: apiKey])
    }

    private func provider(_ client: any HTTPClient) -> InfobipBillingProvider {
        InfobipBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
