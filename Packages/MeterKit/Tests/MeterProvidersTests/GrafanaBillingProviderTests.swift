import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GrafanaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "glc_token-MUST-NOT-LEAK"
    private let orgSlug = "tollcat"

    @Test("amountDue 相加是当月已出账")
    func readsAmountDue() async throws {
        let client = LiveProviderHarness.stub([
            (billedUsageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("grafana-billed-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer，month/year 是日历月")
    func usesBearerAndCalendarMonth() async throws {
        let client = LiveProviderHarness.stub([
            (billedUsageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("grafana-billed-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(billedUsageURL.query?.contains("month=8") == true)
        #expect(billedUsageURL.query?.contains("year=2026") == true)
    }

    @Test("当月还没出账是未读快照，不是 $0")
    func emptyItemsIsUnread() async throws {
        let client = LiveProviderHarness.stub([
            (billedUsageURL, LiveProviderHarness.json(["items": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    @Test("缺少 Org slug")
    func missingOrgSlug() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .grafana, fields: [.apiToken: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var billedUsageURL: URL {
        GrafanaBillingProvider.billedUsageURL(
            orgSlug: orgSlug,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .grafana, fields: [.apiToken: secret, .accountID: orgSlug])
    }

    private func provider(_ client: any HTTPClient) -> GrafanaBillingProvider {
        GrafanaBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
