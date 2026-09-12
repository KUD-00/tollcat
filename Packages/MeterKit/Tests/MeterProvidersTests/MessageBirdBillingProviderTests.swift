import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MessageBirdBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "messagebird-key-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("euros 按目录汇率折")
    func convertsEuros() async throws {
        let client = LiveProviderHarness.stub([
            (
                MessageBirdBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("messagebird-balance"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "113.3")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 AccessKey")
    func usesAccessKey() async throws {
        let client = LiveProviderHarness.stub([
            (
                MessageBirdBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("messagebird-balance"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "AccessKey \(secret)")
    }

    @Test("credits 不是钱")
    func rejectsCredits() async {
        let client = LiveProviderHarness.stub([
            (
                MessageBirdBillingProvider.balanceURL,
                LiveProviderHarness.json([
                    "payment": "prepaid",
                    "type": "credits",
                    "amount": 9,
                ])
            ),
        ])
        await #expect(throws: ProviderError.unsupportedCurrency(providerID: .messagebird)) {
            try await provider(client).fetch(credential: credential)
        }
    }

    @Test("后付费这条接口给 0，当畸形响应")
    func rejectsPostpaid() async {
        let client = LiveProviderHarness.stub([
            (
                MessageBirdBillingProvider.balanceURL,
                LiveProviderHarness.json([
                    "payment": "postpaid",
                    "type": "euros",
                    "amount": 0,
                ])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("type 映射")
    func mapsCurrencyNames() {
        #expect(MessageBirdBillingProvider.currencyCode("euros") == "EUR")
        #expect(MessageBirdBillingProvider.currencyCode("pounds") == "GBP")
        #expect(MessageBirdBillingProvider.currencyCode("dollars") == "USD")
        #expect(MessageBirdBillingProvider.currencyCode("JPY") == "JPY")
        #expect(MessageBirdBillingProvider.currencyCode("credits") == nil)
    }

    private var credential: Credential {
        Credential(providerID: .messagebird, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MessageBirdBillingProvider {
        MessageBirdBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
