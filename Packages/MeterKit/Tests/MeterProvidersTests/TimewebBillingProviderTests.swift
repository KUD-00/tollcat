import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TimewebBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "twc_token_MUST-NOT-LEAK"

    @Test("monthly_cost + currency")
    func readsMonthlyCost() async throws {
        let url = TimewebBillingProvider.financesURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "finances": [
                        "balance": 12.0,
                        "currency": "USD",
                        "hourly_cost": 1.5,
                        "monthly_cost": 1234.56,
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1234.56")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = TimewebBillingProvider.financesURL
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
        Credential(providerID: .timeweb, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> TimewebBillingProvider {
        TimewebBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
