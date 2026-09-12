import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CloudheedBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "ch_token_MUST-NOT-LEAK"

    @Test("total + currency from usage")
    func readsUsageTotal() async throws {
        let url = CloudheedBillingProvider.usageURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "period": [
                        "start": "2026-09-01T00:00:00Z",
                        "end": "2026-09-30T23:59:59Z",
                    ],
                    "usage": [
                        "compute": ["hours": 720, "amount": 79.99],
                        "storage": ["gb": 25.5, "amount": 2.55],
                    ],
                    "total": 82.54,
                    "currency": "USD",
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "82.54")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = CloudheedBillingProvider.usageURL
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
        Credential(providerID: .cloudheed, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> CloudheedBillingProvider {
        CloudheedBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
