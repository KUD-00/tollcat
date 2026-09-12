import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct UpCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "ucat_MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("total_amount 是本月扣款，欧元按目录汇率折")
    func readsMonthlyTotal() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("upcloud-billing-summary"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "58.69")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer，路径带 YYYY-MM")
    func usesBearerAndPeriod() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("upcloud-billing-summary"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(summaryURL.path.hasSuffix("/1.3/account/billing/summary/2026-08"))
    }

    @Test("没有 total_amount 是畸形响应")
    func missingTotal() async {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.json(["currency": "EUR"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var summaryURL: URL {
        UpCloudBillingProvider.summaryURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .upcloud, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> UpCloudBillingProvider {
        UpCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
