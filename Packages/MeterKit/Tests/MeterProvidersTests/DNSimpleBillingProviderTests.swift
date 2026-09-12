import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DNSimpleBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "dnsimple-token-MUST-NOT-LEAK"
    private let account = "1385"

    @Test("本月 collected charges USD 合计")
    func sumsCollectedCharges() async throws {
        let url = DNSimpleBillingProvider.chargesURL(accountID: account)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "invoiced_at": "2026-08-10T05:53:36Z",
                            "total_amount": "14.50",
                            "balance_amount": "0.00",
                            "reference": "1-2",
                            "state": "collected",
                            "items": [["description": "Register example.com", "amount": "14.50"]],
                        ],
                        [
                            "invoiced_at": "2026-08-12T05:53:36Z",
                            "total_amount": "20.00",
                            "state": "refunded",
                            "reference": "2-2",
                        ],
                        [
                            "invoiced_at": "2026-07-01T05:53:36Z",
                            "total_amount": "99.00",
                            "state": "collected",
                            "reference": "old",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "14.50")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = DNSimpleBillingProvider.chargesURL(accountID: account)
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
        Credential(providerID: .dnsimple, fields: [.apiToken: secret, .accountID: account])
    }

    private func provider(_ client: any HTTPClient) -> DNSimpleBillingProvider {
        DNSimpleBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
