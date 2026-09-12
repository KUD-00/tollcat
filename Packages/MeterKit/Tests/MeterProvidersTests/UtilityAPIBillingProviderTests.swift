import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct UtilityAPIBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "utilityapi-token-MUST-NOT-LEAK"

    @Test("本月 bill_total_cost USD 合计")
    func sumsCurrentMonthBills() async throws {
        let client = LiveProviderHarness.stub([
            (
                UtilityAPIBillingProvider.billsURL,
                LiveProviderHarness.json([
                    [
                        "uid": "b1",
                        "utility": "PG&E",
                        "base": [
                            "bill_start_date": "2026-08-01T00:00:00Z",
                            "bill_end_date": "2026-08-31T00:00:00Z",
                            "bill_total_cost": 42.5,
                        ],
                    ],
                    [
                        "uid": "old",
                        "utility": "SCE",
                        "base": [
                            "bill_end_date": "2026-07-15T00:00:00Z",
                            "bill_total_cost": 999.0,
                        ],
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = UtilityAPIBillingProvider.billsURL
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
        Credential(providerID: .utilityapi, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> UtilityAPIBillingProvider {
        UtilityAPIBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
