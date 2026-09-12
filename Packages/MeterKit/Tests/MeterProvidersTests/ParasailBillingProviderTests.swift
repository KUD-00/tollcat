import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ParasailBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "psk-parasail-MUST-NOT-LEAK"

    @Test("current invoice total USD")
    func readsCurrentInvoice() async throws {
        let url = ParasailBillingProvider.currentURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "id": "inv-1",
                    "status": "DRAFT",
                    "type": "USAGE",
                    "total": 52.89,
                    "line_items": [
                        ["name": "Serverless Input", "total": 0.75, "type": "usage"],
                        ["name": "Dedicated GPU Hours", "total": 52.80, "type": "usage"],
                        ["name": "Commit", "total": 100, "type": "commit_purchase"],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "52.89")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ParasailBillingProvider.currentURL
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
        Credential(providerID: .parasail, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ParasailBillingProvider {
        ParasailBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
