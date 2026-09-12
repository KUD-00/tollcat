import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MySendingBoxBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "msb-key-MUST-NOT-LEAK"

    @Test("本月 letters price.total 欧元折美元")
    func sumsCurrentMonth() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = MySendingBoxBillingProvider.lettersURL(page: 1, window: window)
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("mysendingbox-letters"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD != nil)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .mysendingbox, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MySendingBoxBillingProvider {
        MySendingBoxBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.catalogRates
        )
    }
}
