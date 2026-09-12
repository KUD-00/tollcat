import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PlivoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let authID = "MAXXXXXXXXXXXXXXXXXX"
    private let token = "plivo-token-MUST-NOT-LEAK"

    @Test("meta.total_spend 是本月花费")
    func readsTotalSpend() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("plivo-usage-summary"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.40")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Basic，窗口含本月首日到今天")
    func usesBasicAndWindow() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("plivo-usage-summary"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == PlivoBillingProvider.basicAuthorization(authID: authID, token: token)
        )
        #expect(summaryURL.query?.contains("from_date=2026-08-01") == true)
        #expect(summaryURL.query?.contains("to_date=2026-08-16") == true)
        #expect(summaryURL.query?.contains("granularity=month") == true)
    }

    @Test("没有 total_spend 是畸形响应")
    func missingTotal() async {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.json(["meta": ["currency": "USD"] as [String: Any]])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var summaryURL: URL {
        PlivoBillingProvider.summaryURL(
            authID: authID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            now: now,
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .plivo, fields: [.accountID: authID, .apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> PlivoBillingProvider {
        PlivoBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(.usdOnly)
        )
    }
}
