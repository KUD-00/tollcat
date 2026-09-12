import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MariaDBCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "skysql-key-MUST-NOT-LEAK"

    @Test("total 是本月用量分摊")
    func readsBillTotal() async throws {
        let client = LiveProviderHarness.stub([
            (billsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("mariadb-bills"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.4")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 X-API-Key，year 和 month 是本月")
    func usesAPIKeyAndPeriod() async throws {
        let client = LiveProviderHarness.stub([
            (billsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("mariadb-bills"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == secret)
        #expect(billsURL.query?.contains("year=2026") == true)
        #expect(billsURL.query?.contains("month=8") == true)
    }

    @Test("没有 total 是畸形响应")
    func missingTotal() async {
        let client = LiveProviderHarness.stub([
            (billsURL, LiveProviderHarness.json(["currency": "USD", "period": "2026-08"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var billsURL: URL {
        MariaDBCloudBillingProvider.billsURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .mariadb, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MariaDBCloudBillingProvider {
        MariaDBCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(.usdOnly)
        )
    }
}
