import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct NomosBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "nomos-client"
    private let clientSecret = "nomos-secret-MUST-NOT-LEAK"
    private let bearer = "nomos-access-token"
    private let eurRate = Decimal(string: "1.10")!

    @Test("usage invoice EUR total; skip prepayment")
    func readsUsageInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                NomosBillingProvider.tokenURL,
                LiveProviderHarness.json([
                    "access_token": bearer,
                    "token_type": "Bearer",
                    "expires_in": 3600,
                ] as [String: Any])
            ),
            (
                ProviderURL.https(
                    host: NomosBillingProvider.apiHost,
                    path: "/invoices",
                    query: [
                        URLQueryItem(name: "limit", value: "100"),
                        URLQueryItem(name: "filter[type][eq]", value: "usage"),
                    ]
                ),
                LiveProviderHarness.json([
                    "object": "list",
                    "items": [
                        [
                            "object": "invoice",
                            "id": "inv_1",
                            "invoice_number": "H-001",
                            "type": "usage",
                            "status": "paid",
                            "month": 8,
                            "year": 2026,
                            "period_start": "2026-07-31T22:00:00Z",
                            "total": 100.0,
                        ],
                        [
                            "object": "invoice",
                            "id": "inv_old",
                            "invoice_number": "H-000",
                            "type": "usage",
                            "status": "paid",
                            "month": 7,
                            "year": 2026,
                            "total": 999.0,
                        ],
                        [
                            "object": "invoice",
                            "id": "inv_pre",
                            "type": "prepayment",
                            "status": "open",
                            "month": 8,
                            "year": 2026,
                            "total": 50.0,
                        ],
                    ],
                    "has_more": false,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 100 EUR * 1.10 = 110 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([clientSecret, bearer]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = NomosBillingProvider.tokenURL
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
        Credential(
            providerID: .nomos,
            fields: [
                .clientID: clientID,
                .clientSecret: clientSecret,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> NomosBillingProvider {
        NomosBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }
}
