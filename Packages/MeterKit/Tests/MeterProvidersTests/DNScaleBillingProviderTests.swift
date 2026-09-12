import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DNScaleBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "dnscale-key-MUST-NOT-LEAK"
    private let eurRate = Decimal(string: "1.10")!

    @Test("summary charges.total EUR")
    func readsSummary() async throws {
        let client = LiveProviderHarness.stub([
            (
                DNScaleBillingProvider.summaryURL,
                LiveProviderHarness.json([
                    "status": "success",
                    "data": [
                        "plan": ["id": "plan_pro", "name": "Pro", "currency": "EUR"],
                        "charges": [
                            "base": 29.0,
                            "overage_queries": 1.0,
                            "overage_zones": 0.0,
                            "total": 30.0,
                            "currency": "EUR",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 30 EUR * 1.10 = 33 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "33")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = DNScaleBillingProvider.summaryURL
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
        Credential(providerID: .dnscale, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> DNScaleBillingProvider {
        DNScaleBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }
}
