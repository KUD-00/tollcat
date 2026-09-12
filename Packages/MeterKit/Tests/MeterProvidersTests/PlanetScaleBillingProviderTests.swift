import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PlanetScaleBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let tokenID = "pscale-id-MUST-NOT"
    private let token = "pscale-token-MUST-NOT-LEAK"
    private let org = "acme"

    @Test("当前账期发票合计")
    func currentInvoiceTotal() async throws {
        let client = LiveProviderHarness.stub([
            (PlanetScaleBillingProvider.invoicesURL(organization: org), LiveProviderHarness.body(LiveProviderHarness.fixture("planetscale-invoices"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 18.40))
        #expect(client.leakedSecrets([token]).isEmpty)
        #expect(client.urls.allSatisfy { !$0.absoluteString.contains(token) })
    }

    @Test("没有覆盖今天的发票是未读快照，不是 $0")
    func noCurrentInvoice() async throws {
        let client = LiveProviderHarness.stub([
            (PlanetScaleBillingProvider.invoicesURL(organization: org), LiveProviderHarness.json([
                "data": [
                    [
                        "id": "old",
                        "total": "9",
                        "billing_period_start": "2026-07-01",
                        "billing_period_end": "2026-07-31",
                    ],
                ],
            ])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    @Test("缺组织 slug")
    func missingOrg() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .planetscale, fields: [
                    .accessKeyID: tokenID,
                    .apiToken: token,
                ])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var credential: Credential {
        Credential(providerID: .planetscale, fields: [
            .accessKeyID: tokenID,
            .apiToken: token,
            .accountID: org,
        ])
    }

    private func provider(_ client: any HTTPClient) -> PlanetScaleBillingProvider {
        PlanetScaleBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
