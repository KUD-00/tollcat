import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TogetherBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "together-key-MUST-NOT-LEAK"

    @Test("billing/usage USD cost windows")
    func sumsUsageWindows() async throws {
        let url = ProviderURL.https(
            host: TogetherBillingProvider.apiHost,
            path: "/v1/billing/usage",
            query: [
                URLQueryItem(name: "month", value: "2026-08"),
                URLQueryItem(name: "granularity", value: "day"),
                URLQueryItem(name: "limit", value: "100"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "object": "list",
                    "currency": "USD",
                    "billing_period": "2026-08",
                    "data": [
                        [
                            "date": "2026-08-10",
                            "start_time": "2026-08-10T00:00:00Z",
                            "end_time": "2026-08-11T00:00:00Z",
                            "line_items": [
                                [
                                    "product_name": "Serverless Inference",
                                    "quantity": "1",
                                    "unit_price": "2.50",
                                    "cost": "2.50",
                                    
                                ],
                            ],
                        ],
                        [
                            "date": "2026-08-11",
                            "line_items": [
                                [
                                    "product_name": "Serverless Inference",
                                    "quantity": "1",
                                    "unit_price": "1.25",
                                    "cost": "1.25",
                                    
                                ],
                            ],
                        ],
                    ],
                                    ] as [String: Any])
            ),
        ])
        let snapshot = try await TogetherBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        ).fetch(credential: Credential(providerID: .together, fields: [.apiKey: secret]))
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "3.75")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: TogetherBillingProvider.apiHost,
            path: "/v1/billing/usage",
            query: [
                URLQueryItem(name: "month", value: "2026-08"),
                URLQueryItem(name: "granularity", value: "day"),
                URLQueryItem(name: "limit", value: "100"),
            ]
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await TogetherBillingProvider(
                httpClient: LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))]),
                now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
            ).fetch(credential: Credential(providerID: .together, fields: [.apiKey: secret]))
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await TogetherBillingProvider(
                httpClient: LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))]),
                now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
            ).fetch(credential: Credential(providerID: .together, fields: [.apiKey: secret]))
        }
    }
}
