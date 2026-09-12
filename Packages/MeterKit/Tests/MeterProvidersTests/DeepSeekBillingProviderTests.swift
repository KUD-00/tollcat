import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DeepSeekBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk-deepseek-MUST-NOT-LEAK"
    private let cny = ExchangeRates(usdPerUnit: ["CNY": Decimal(string: "0.1404")!])

    @Test("USD 余额直接记账")
    func usdBalance() async throws {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("deepseek-user-balance"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: 42))
        #expect(snapshot.wallets?.count == 1)
        #expect(snapshot.wallets?.first?.currency == "USD")
        #expect(!snapshot.isCurrencyConverted)
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("只有人民币时按目录汇率折")
    func convertsCNY() async throws {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.json([
                "balance_infos": [
                    [
                        "currency": "CNY",
                        "total_balance": "110.00",
                    ],
                ],
            ])),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "15.44")!))
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == 110)
        #expect(snapshot.wallets?.count == 1)
        #expect(snapshot.isCurrencyConverted)
    }

    @Test("没有汇率表时只有人民币仍然拒绝")
    func rejectsCNYWithoutRates() async {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.json([
                "balance_infos": [
                    [
                        "currency": "CNY",
                        "total_balance": "110.00",
                    ],
                ],
            ])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("两个钱包都有钱时合计，不丢掉人民币")
    func sumsBothFundedWallets() async throws {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.json([
                "balance_infos": [
                    ["currency": "CNY", "total_balance": "110.00"],
                    ["currency": "usd", "total_balance": "8.5"],
                ],
            ])),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "23.94")!))
        #expect(snapshot.converted == nil)
        #expect(snapshot.wallets?.count == 2)
        #expect(snapshot.wallets?[0].currency == "CNY")
        #expect(snapshot.wallets?[1].currency == "USD")
        #expect(snapshot.wallets?[1].amount == Decimal(string: "8.5"))
        #expect(snapshot.isCurrencyConverted)
    }

    @Test("空着的美元槽也留下，合计走人民币")
    func keepsEmptyUSDSlotAndConvertsCNY() async throws {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.json([
                "is_available": true,
                "balance_infos": [
                    [
                        "currency": "CNY",
                        "granted_balance": "0.00",
                        "topped_up_balance": "14.17",
                        "total_balance": "14.17",
                    ],
                    [
                        "currency": "USD",
                        "granted_balance": "0.00",
                        "topped_up_balance": "0.00",
                        "total_balance": "0.00",
                    ],
                ],
            ])),
        ])
        let snapshot = try await provider(client, rates: cny).fetch(credential: credential)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "1.99")!))
        #expect(snapshot.converted?.currency == "CNY")
        #expect(snapshot.converted?.amount == Decimal(string: "14.17"))
        #expect(snapshot.wallets?.count == 2)
        #expect(snapshot.wallets?[0].amount == Decimal(string: "14.17"))
        #expect(snapshot.wallets?[1].amount == 0)
        #expect(snapshot.isCurrencyConverted)
    }

    @Test("两个槽都是 0 记成余额 $0，不是没读到")
    func zeroWalletsAreEmptyPrepaid() async throws {
        let client = LiveProviderHarness.stub([
            (DeepSeekBillingProvider.balanceURL, LiveProviderHarness.json([
                "balance_infos": [
                    ["currency": "CNY", "total_balance": "0.00"],
                    ["currency": "USD", "total_balance": "0.00"],
                ],
            ])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == Money(usd: 0))
        #expect(snapshot.hasBillableMetrics)
        #expect(!snapshot.isCurrencyConverted)
    }

    @Test("缺少 key")
    func missingKey() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .deepseek, fields: [:])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var credential: Credential {
        Credential(providerID: .deepseek, fields: [.apiKey: secret])
    }

    private func provider(
        _ client: any HTTPClient,
        rates: ExchangeRates = .usdOnly
    ) -> DeepSeekBillingProvider {
        DeepSeekBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(rates))
    }
}
