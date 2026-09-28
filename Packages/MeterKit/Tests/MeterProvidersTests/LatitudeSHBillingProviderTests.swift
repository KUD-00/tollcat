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
            projectsResponse(currency: "USD"),
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

    @Test("限定 projectID 时仍按团队币种换算")
    func scopedProjectUsesTeamCurrency() async throws {
        let client = LiveProviderHarness.stub([
            projectsResponse(currency: "GBP"),
            (
                LatitudeSHBillingProvider.usageURL(projectID: projectID),
                LiveProviderHarness.json([
                    "data": [
                        "attributes": [
                            "period": [
                                "start": "2026-08-01T00:00:00Z",
                                "end": "2026-09-01T00:00:00Z",
                            ],
                            "price": 10000,
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await LatitudeSHBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["GBP": Decimal(string: "1.25")!]))
        ).fetch(credential: credential)
        // 100.00 GBP × 1.25 = 125.00 USD，明细行同一个汇率
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "125")!))
        #expect(snapshot.converted?.currency == "GBP")
        #expect(snapshot.lines?.first?.amountUSD == Money(usd: Decimal(string: "125")!))
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = LatitudeSHBillingProvider.projectsURL
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

    private func projectsResponse(currency: String) -> (URL, StubHTTPResponse) {
        (
            LatitudeSHBillingProvider.projectsURL,
            LiveProviderHarness.json([
                "data": [
                    [
                        "id": projectID,
                        "attributes": [
                            "name": "Demo",
                            "team": ["currency": ["code": currency]],
                        ],
                    ],
                ]
            ] as [String: Any])
        )
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
