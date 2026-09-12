import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct StripeBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "rk_live_MUST-NOT-LEAK"

    @Test("fee 美分按日加总成本月手续费")
    func sumsUSDFeesByDay() async throws {
        let url = StripeBillingProvider.listURL(
            createdGTE: createdGTE,
            createdLT: createdLT,
            startingAfter: nil
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("stripe-balance-transactions"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "2.63")!))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "0.88")!))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 5)] == Money(usd: Decimal(string: "1.75")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        #expect(client.urls.allSatisfy { !$0.absoluteString.contains(secret) })
    }

    @Test("非 USD 且有手续费就拒绝换算")
    func rejectsNonUSDFees() async {
        let url = StripeBillingProvider.listURL(
            createdGTE: createdGTE,
            createdLT: createdLT,
            startingAfter: nil
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.json([
                "has_more": false,
                "data": [
                    ["id": "txn_eur", "fee": 40, "currency": "eur", "created": createdGTE],
                ],
            ])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("翻页游标用完或撞上限")
    func paginationAdvance() {
        #expect(
            StripeBillingProvider.nextPage(
                hasMore: false,
                lastID: "txn_1",
                previousLast: nil,
                pages: 1
            ) == .done
        )
        #expect(
            StripeBillingProvider.nextPage(
                hasMore: true,
                lastID: "txn_2",
                previousLast: "txn_1",
                pages: 1
            ) == .more("txn_2")
        )
        #expect(
            StripeBillingProvider.nextPage(
                hasMore: true,
                lastID: "txn_2",
                previousLast: "txn_1",
                pages: StripeBillingProvider.maxPages
            ) == .truncated
        )
    }

    @Test("美分转美元")
    func centsToMoney() {
        #expect(StripeBillingProvider.money(fromCents: 59) == Money(usd: Decimal(string: "0.59")!))
        #expect(StripeBillingProvider.money(fromCents: 0) == .zero)
    }

    private var createdGTE: Int {
        Int(LiveProviderHarness.date(2026, 8, 1).timeIntervalSince1970)
    }

    private var createdLT: Int {
        Int(now.timeIntervalSince1970)
    }

    private var credential: Credential {
        Credential(providerID: .stripe, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> StripeBillingProvider {
        StripeBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly))
    }
}
