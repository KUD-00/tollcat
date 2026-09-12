import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AIMLAPIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "aiml-key-MUST-NOT-LEAK"

    @Test("current_balance 官方美元原样计入")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                AIMLAPIBillingProvider.billingURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("aimlapi-billing"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "123.45")!))
        #expect(!snapshot.isCurrencyConverted)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (
                AIMLAPIBillingProvider.billingURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("aimlapi-billing"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("缺 current_balance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (AIMLAPIBillingProvider.billingURL, LiveProviderHarness.json(["currency": "USD"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .aimlapi, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> AIMLAPIBillingProvider {
        AIMLAPIBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
