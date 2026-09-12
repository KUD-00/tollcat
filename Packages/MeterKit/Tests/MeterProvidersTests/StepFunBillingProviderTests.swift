import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct StepFunBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-stepfun-MUST-NOT-LEAK"
    private let cny = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])

    @Test("国内站人民币按目录汇率折成美元")
    func officialCNYConverts() async throws {
        let client = LiveProviderHarness.stub([
            (
                StepFunBillingProvider.accountsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("stepfun-accounts"))
            ),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "14.04")!))
        #expect(snapshot.isCurrencyConverted)
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == 100)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("没有汇率表时官方人民币仍然拒绝")
    func officialCNYIsRejectedWithoutRates() async {
        let client = LiveProviderHarness.stub([
            (
                StepFunBillingProvider.accountsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("stepfun-accounts"))
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("缺余额字段是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (
                StepFunBillingProvider.accountsURL,
                LiveProviderHarness.json(["object": "account", "type": "prepaid"])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .stepfun, fields: [.apiKey: secret])
    }

    private func provider(
        _ client: any HTTPClient,
        rates: ExchangeRates = .usdOnly
    ) -> StepFunBillingProvider {
        StepFunBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(rates)
        )
    }
}

struct StepFunAIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-stepfun-ai-MUST-NOT-LEAK"

    @Test("国际站美元原样计入，不走汇率")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                StepFunAIBillingProvider.accountsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("stepfunai-accounts"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(!snapshot.isCurrencyConverted)
        #expect(snapshot.converted == nil)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("打的是国际站，不是国内站")
    func hitsInternationalHost() async throws {
        let client = LiveProviderHarness.stub([
            (
                StepFunAIBillingProvider.accountsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("stepfunai-accounts"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.urls == [StepFunAIBillingProvider.accountsURL])
        #expect(StepFunAIBillingProvider.accountsURL.host == "api.stepfun.ai")
        #expect(StepFunBillingProvider.accountsURL.host == "api.stepfun.com")
    }

    @Test("缺余额字段是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (
                StepFunAIBillingProvider.accountsURL,
                LiveProviderHarness.json(["object": "account", "type": "prepaid"])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .stepfunAI, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> StepFunAIBillingProvider {
        StepFunAIBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
