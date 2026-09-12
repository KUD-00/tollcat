import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct HubbleBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "hubble-key-MUST-NOT-LEAK"
    private let org = "org_test123"

    @Test("total_balance; skip DRAFT")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let stamp = current.start.addingTimeInterval(86400 * 4).timeIntervalSince1970
        let url = HubbleBillingProvider.invoicesURL(orgID: org)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "invoice_id": "inv_1",
                            "invoice_number": "HB-001",
                            "issue_timestamp": stamp,
                            "status": "COMPLETED",
                            "total_balance": 42.5,
                        ],
                        [
                            "invoice_id": "inv_draft",
                            "issue_timestamp": stamp,
                            "status": "DRAFT",
                            "total_balance": 99.0,
                        ],
                        [
                            "invoice_id": "inv_old",
                            "issue_timestamp": 1_577_836_800,
                            "status": "COMPLETED",
                            "total_balance": 10.0,
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.50")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = HubbleBillingProvider.invoicesURL(orgID: org)
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .hubble, fields: [.apiKey: token, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> HubbleBillingProvider {
        HubbleBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
