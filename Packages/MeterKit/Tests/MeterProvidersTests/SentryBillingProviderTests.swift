import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct SentryBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "SENTRY-TOKEN-MUST-NOT-LEAK"
    private let org = "meter-fixture"

    @Test("报的是免费额度占比，不是编出来的金额")
    func reportsQuotaRatioNotMoney() async throws {
        let client = LiveProviderHarness.stub([
            (statsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("sentry-stats"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.freeQuotaUsedRatio == 3100.0 / 5000.0)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("超过免费额度就顶在 100%，不外溢成负数或大于 1")
    func ratioSaturates() {
        #expect(SentryBillingProvider.ratio(used: 50_000, included: 5_000) == 1)
        #expect(SentryBillingProvider.ratio(used: -3, included: 5_000) == 0)
        #expect(SentryBillingProvider.ratio(used: 100, included: 0) == 0)
    }

    @Test("多个分组的 sum(quantity) 相加")
    func sumsAcrossGroups() {
        let stats = SentryBillingProvider.Stats(groups: [
            SentryBillingProvider.Group(totals: ["sum(quantity)": 1_200]),
            SentryBillingProvider.Group(totals: ["sum(quantity)": 800]),
        ])
        #expect(SentryBillingProvider.acceptedErrors(stats) == 2_000)
    }

    @Test("查询只要 accepted 的 error，别把被限流的也算进额度")
    func queryFiltersToAcceptedErrors() {
        let query = statsURL.query ?? ""
        #expect(query.contains("outcome=accepted"))
        #expect(query.contains("category=error"))
        #expect(query.contains("field=sum(quantity)".addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? "") || query.contains("sum(quantity)"))
    }

    @Test("缺组织 slug 就报缺凭据")
    func requiresOrganizationSlug() async {
        let client = LiveProviderHarness.stub([])
        let partial = Credential(providerID: .sentry, fields: [.apiToken: token])
        await #expect(throws: ProviderError.missingCredential(providerID: .sentry)) {
            _ = try await provider(client).fetch(credential: partial)
        }
    }

    private var statsURL: URL {
        SentryBillingProvider.statsURL(
            org: org,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .sentry, fields: [.apiToken: token, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> SentryBillingProvider {
        SentryBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
