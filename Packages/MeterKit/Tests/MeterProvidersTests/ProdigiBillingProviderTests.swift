import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ProdigiBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "prodigi-key-MUST-NOT-LEAK"

    @Test("charges totalCost 相加（含退款负数）")
    func sumsCharges() async throws {
        let url = ProdigiBillingProvider.ordersURL(
            from: CalendarMonthWindow.current(now: now, calendar: calendar).start,
            to: CalendarMonthWindow.current(now: now, calendar: calendar).nextStart,
            top: ProdigiBillingProvider.pageSize,
            skip: 0
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("prodigi-orders"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "8.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .prodigi, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ProdigiBillingProvider {
        ProdigiBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
