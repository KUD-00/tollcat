import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MoonshotBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-kimi-MUST-NOT-LEAK"

    private let cny = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])

    @Test("官方人民币按目录汇率折成美元")
    func officialCNYConverts() async throws {
        let client = LiveProviderHarness.stub([
            (MoonshotBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("moonshot-user-balance"))),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "6.96")!))
        #expect(snapshot.isCurrencyConverted)
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == Decimal(string: "49.58894"))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("没有汇率表时官方人民币仍然拒绝")
    func officialCNYIsRejectedWithoutRates() async {
        let client = LiveProviderHarness.stub([
            (MoonshotBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("moonshot-user-balance"))),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("官方整数余额也按人民币折")
    func integerBalanceConverts() async throws {
        let client = LiveProviderHarness.stub([
            (
                MoonshotBillingProvider.balanceURL,
                LiveProviderHarness.json([
                    "code": 0,
                    "data": [
                        "available_balance": 15,
                        "cash_balance": 0,
                        "voucher_balance": 15,
                    ] as [String: Any],
                    "scode": "0x0",
                    "status": true,
                ])
            ),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "2.11")!))
        #expect(snapshot.isCurrencyConverted)
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == 15)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("缺余额字段是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (MoonshotBillingProvider.balanceURL, LiveProviderHarness.json(["code": 0, "data": [:] as [String: Any]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .moonshot, fields: [.apiKey: secret])
    }

    private func provider(
        _ client: any HTTPClient,
        rates: ExchangeRates = .usdOnly
    ) -> MoonshotBillingProvider {
        MoonshotBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(rates))
    }
}

struct MoonshotAIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-moonshot-MUST-NOT-LEAK"

    @Test("国际站美元原样计入，不走汇率")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                MoonshotAIBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("moonshotai-user-balance"))
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

    @Test("缺余额字段是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (MoonshotAIBillingProvider.balanceURL, LiveProviderHarness.json(["code": 0, "data": [:] as [String: Any]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    @Test("打的是国际站，不是国内站")
    func hitsInternationalHost() async throws {
        let client = LiveProviderHarness.stub([
            (
                MoonshotAIBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("moonshotai-user-balance"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.urls == [MoonshotAIBillingProvider.balanceURL])
        #expect(MoonshotAIBillingProvider.balanceURL.host == "api.moonshot.ai")
        #expect(MoonshotBillingProvider.balanceURL.host == "api.moonshot.cn")
    }

    private var credential: Credential {
        Credential(providerID: .moonshotAI, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MoonshotAIBillingProvider {
        MoonshotAIBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
