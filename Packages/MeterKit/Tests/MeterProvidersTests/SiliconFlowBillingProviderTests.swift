import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct SiliconFlowBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-silicon-MUST-NOT-LEAK"
    private let cny = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])

    @Test("totalBalance 按人民币折成美元")
    func officialCNYConverts() async throws {
        let client = LiveProviderHarness.stub([
            (
                SiliconFlowBillingProvider.userInfoURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("siliconflow-user-info"))
            ),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "12.48")!))
        #expect(snapshot.isCurrencyConverted)
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == Decimal(string: "88.88"))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("没有汇率表时官方人民币仍然拒绝")
    func officialCNYIsRejectedWithoutRates() async {
        let client = LiveProviderHarness.stub([
            (
                SiliconFlowBillingProvider.userInfoURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("siliconflow-user-info"))
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
                SiliconFlowBillingProvider.userInfoURL,
                LiveProviderHarness.json(["code": 20000, "data": [:] as [String: Any]])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .siliconflow, fields: [.apiKey: secret])
    }

    private func provider(
        _ client: any HTTPClient,
        rates: ExchangeRates = .usdOnly
    ) -> SiliconFlowBillingProvider {
        SiliconFlowBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(rates)
        )
    }
}
