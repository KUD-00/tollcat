import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ConfluentBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "confluent-key-MUST-NOT-LEAK"
    private let secret = "confluent-secret-MUST-NOT-LEAK"

    @Test("amount 相加是本月花费，日线按 start_date")
    func sumsDailyAmounts() async throws {
        let client = LiveProviderHarness.stub([
            (costsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("confluent-costs"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: 13))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 8))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)] == Money(usd: 5))
        #expect(client.leakedSecrets([key, secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Basic，区间含首不含尾")
    func usesBasicAndExclusiveEnd() async throws {
        let client = LiveProviderHarness.stub([
            (costsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("confluent-costs"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == ConfluentBillingProvider.basicAuthorization(id: key, secret: secret)
        )
        #expect(costsURL.query?.contains("start_date=2026-08-01") == true)
        #expect(costsURL.query?.contains("end_date=2026-09-01") == true)
    }

    @Test("只跟本 host 的下一页")
    func ignoresForeignNext() {
        #expect(
            ConfluentBillingProvider.nextPageURL(
                "https://api.confluent.cloud/billing/v1/costs?page_token=abc"
            )?.host == ConfluentBillingProvider.apiHost
        )
        #expect(ConfluentBillingProvider.nextPageURL("https://example.invalid/steal") == nil)
        #expect(ConfluentBillingProvider.nextPageURL(nil) == nil)
    }

    @Test("翻页把两页金额加起来")
    func paginates() async throws {
        let next = URL(string: "https://api.confluent.cloud/billing/v1/costs?page_token=p2")!
        let page1 = """
        {"metadata":{"next":"\(next.absoluteString)"},"data":[{"start_date":"2026-08-01","amount":3}]}
        """
        let page2 = """
        {"data":[{"start_date":"2026-08-03","amount":4}]}
        """
        let client = LiveProviderHarness.stub([
            (costsURL, LiveProviderHarness.body(Data(page1.utf8))),
            (next, LiveProviderHarness.body(Data(page2.utf8))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: 7))
        #expect(client.requests.count == 2)
    }

    private var costsURL: URL {
        ConfluentBillingProvider.costsURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .confluent, fields: [.clientID: key, .clientSecret: secret])
    }

    private func provider(_ client: any HTTPClient) -> ConfluentBillingProvider {
        ConfluentBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
