import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct SevallaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "sev_token_MUST-NOT-LEAK"
    private let companyID = "fb5e5168-4281-4bec-94c5-0d1584e9e657"

    @Test("sum paas-usage cost USD; company from validate")
    func readsUsageCosts() async throws {
        let validate = SevallaBillingProvider.validateURL
        let usage = SevallaBillingProvider.usageURL(companyID: companyID, periodOffset: 0)
        let client = LiveProviderHarness.stub([
            (
                validate,
                LiveProviderHarness.json([
                    "name": "TollCat",
                    "expires_at": NSNull(),
                    "company": companyID,
                    "status": "active",
                ] as [String: Any])
            ),
            (
                usage,
                LiveProviderHarness.json([
                    "company": [
                        "paas_usage": [
                            [
                                "id": "usage_1",
                                "date": 1_786_320_000_000,
                                "category": "appCompute",
                                "id_resource": "app-1",
                                "usage": 24.5,
                                "cost": 12.75,
                            ],
                            [
                                "id": "usage_2",
                                "date": 1_786_752_000_000,
                                "category": "db",
                                "id_resource": "db-1",
                                "usage": 10,
                                "cost": 3.25,
                            ],
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "16.00")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("accountID overrides validate")
    func accountIDOverride() async throws {
        let usage = SevallaBillingProvider.usageURL(companyID: companyID, periodOffset: 0)
        let client = LiveProviderHarness.stub([
            (
                usage,
                LiveProviderHarness.json([
                    "company": [
                        "paas_usage": [
                            [
                                "id": "usage_1",
                                "date": 1_786_320_000_000,
                                "category": "appBandwidth",
                                "id_resource": "app-1",
                                "usage": 1,
                                "cost": 1.50,
                            ],
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(
                providerID: .sevalla,
                fields: [.apiToken: token, .accountID: companyID]
            )
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1.50")!))
        #expect(client.leakedSecrets([token]).isEmpty)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let validate = SevallaBillingProvider.validateURL
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(validate, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(validate, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .sevalla, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> SevallaBillingProvider {
        SevallaBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
