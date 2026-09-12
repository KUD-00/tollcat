import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct BotpressBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "bp_pat_MUST-NOT-LEAK"
    private let workspace = "wkspace_demo"

    @Test("upcoming invoice lineItems cents")
    func readsLineItemCents() async throws {
        let url = BotpressBillingProvider.upcomingInvoiceURL(workspaceID: workspace)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "total": 4999,
                    "lineItems": [
                        [
                            "id": "li_01",
                            "description": "Pro workspace subscription",
                            "totalInCents": 3999,
                            "currency": "usd",
                        ],
                        [
                            "id": "li_02",
                            "description": "Additional usage charges",
                            "totalInCents": 1000,
                            "currency": "usd",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "49.99")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.value(forHTTPHeaderField: "x-workspace-id") == workspace)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = BotpressBillingProvider.upcomingInvoiceURL(workspaceID: workspace)
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials, url: url)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions, url: url)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        url: URL
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .botpress, fields: [.apiToken: secret, .accountID: workspace])
    }

    private func provider(_ client: any HTTPClient) -> BotpressBillingProvider {
        BotpressBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
