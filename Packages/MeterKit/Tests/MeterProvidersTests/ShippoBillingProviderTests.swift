import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ShippoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "shippo-token-MUST-NOT-LEAK"

    @Test("本月 transactions 展开 rate.amount 合计")
    func sumsExpandedRates() async throws {
        let provider = ShippoBillingProvider(
            httpClient: LiveProviderHarness.stub([]),
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
        let url = ShippoBillingProvider.transactionsURL(
            page: 1,
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("shippo-transactions"))),
        ])
        let snapshot = try await ShippoBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        ).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "19.75")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        _ = provider
    }

    private var credential: Credential {
        Credential(providerID: .shippo, fields: [.apiKey: secret])
    }
}
