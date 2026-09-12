import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct InferenceSHBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "inferencesh-key-MUST-NOT-LEAK"

    @Test("microcents 换算为本月美元")
    func convertsMicrocents() async throws {
        // harness now is 2026-08-15; current month Aug
        let client = LiveProviderHarness.stub([
            (
                InferenceSHBillingProvider.breakdownURL,
                LiveProviderHarness.json([
                    "total_cost": 250_000_000,
                    "timeseries": [
                        [
                            "date": "2026-08-10T00:00:00Z",
                            "per_app": ["ns/app": 100_000_000],
                        ],
                        [
                            "date": "2026-08-12T00:00:00Z",
                            "per_app": ["ns/app": 50_000_000],
                        ],
                        [
                            "date": "2026-07-01T00:00:00Z",
                            "per_app": ["old": 999_000_000],
                        ],
                    ] as [[String: Any]],
                    "per_model": [
                        ["app_endpoint": "ns/app", "cost": 150_000_000, "call_count": 3],
                    ] as [[String: Any]],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.value(forHTTPHeaderField: "X-API-Version") == "2")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = InferenceSHBillingProvider.breakdownURL
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
        Credential(providerID: .inferencesh, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> InferenceSHBillingProvider {
        InferenceSHBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
