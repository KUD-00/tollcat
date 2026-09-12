import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct HerokuBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "HEROKU-TOKEN-MUST-NOT-LEAK"

    @Test("挑周期落在本月那张发票，上个月的不算")
    func picksCurrentMonthInvoice() async throws {
        let client = LiveProviderHarness.stub([
            (
                HerokuBillingProvider.invoicesURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("heroku-invoices"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: 27))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("当月发票还没出就报「没读到」，不是 $0")
    func missingCurrentInvoiceIsNotZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                HerokuBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    ["period_start": "07/01/2026", "period_end": "07/31/2026", "total": 31.5],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    @Test("发票日期是 MM/DD/YYYY，不是 ISO")
    func parsesAmericanSlashDate() {
        let date = HerokuBillingProvider.parseSlashDate("08/01/2026", calendar: calendar)
        #expect(date == LiveProviderHarness.date(2026, 8, 1))
        // ISO 也别退化：万一哪天改了格式还能兜住。
        #expect(
            HerokuBillingProvider.parseSlashDate("2026-08-01", calendar: calendar)
            == LiveProviderHarness.date(2026, 8, 1)
        )
    }

    @Test("Accept 必须带 Heroku 的版本号，否则拿到的是另一套字段")
    func sendsVersionedAccept() async throws {
        let client = LiveProviderHarness.stub([
            (HerokuBillingProvider.invoicesURL, LiveProviderHarness.json([])),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Accept") == HerokuBillingProvider.acceptVersion)
    }

    private var credential: Credential {
        Credential(providerID: .heroku, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> HerokuBillingProvider {
        HerokuBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
