import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct LatitudeSHBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "latitude-key-MUST-NOT-LEAK"
    private let projectID = "proj_demo"

    @Test("周期 usage price cents 换算，忽略 credit balance")
    func sumsPeriodUsagePrice() async throws {
        let client = LiveProviderHarness.stub([
            (
                LatitudeSHBillingProvider.usageURL(projectID: projectID),
                LiveProviderHarness.json([
                    "data": [
                        "id": "",
                        "type": "billing_usage",
                        "attributes": [
                            "period": [
                                "start": "2026-08-01T00:00:00Z",
                                "end": "2026-09-01T00:00:00Z",
                            ],
                            "available_credit_balance": 99999,
                            "amount": 2500,
                            "price": 2500,
                            "products": [] as [Any],
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 2500 cents = 25.00 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "25")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = LatitudeSHBillingProvider.usageURL(projectID: projectID)
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
        Credential(providerID: .latitudesh, fields: [.apiKey: secret, .projectID: projectID])
    }

    private func provider(_ client: any HTTPClient) -> LatitudeSHBillingProvider {
        LatitudeSHBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
