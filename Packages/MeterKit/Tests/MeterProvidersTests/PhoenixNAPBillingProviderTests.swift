import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PhoenixNAPBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "pnap-client-MUST-NOT-LEAK"
    private let clientSecret = "pnap-secret-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.1")!

    @Test("发票 amount+currency 按 sentOn 归入本月；先 OAuth 换票")
    func sumsCurrentMonthInvoices() async throws {
        let tokenURL = PhoenixNAPBillingProvider.tokenURL
        let invoicesURL = PhoenixNAPBillingProvider.invoicesURL(offset: 0)
        let client = LiveProviderHarness.stub([
            (
                tokenURL,
                LiveProviderHarness.json(["access_token": "pnap-access", "token_type": "bearer"] as [String: Any])
            ),
            (
                invoicesURL,
                LiveProviderHarness.json([
                    "limit": 100,
                    "offset": 0,
                    "total": 2,
                    "results": [
                        [
                            "id": "inv-aug",
                            "number": "13218-1180326",
                            "currency": "EUR",
                            "amount": 42.5,
                            "outstandingAmount": 0,
                            "status": "PAID",
                            "sentOn": "2026-08-12T10:00:00.000Z",
                            "dueDate": "2026-08-26T10:00:00.000Z",
                        ],
                        [
                            "id": "inv-jul",
                            "number": "13218-1180001",
                            "currency": "EUR",
                            "amount": 99,
                            "outstandingAmount": 0,
                            "status": "PAID",
                            "sentOn": "2026-07-05T10:00:00.000Z",
                            "dueDate": "2026-07-19T10:00:00.000Z",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "46.75")!))
        #expect(client.leakedSecrets([clientSecret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let auth = try #require(client.requests.first)
        #expect(auth.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Basic ") == true)
        let invoiceReq = try #require(client.requests.dropFirst().first)
        #expect(invoiceReq.value(forHTTPHeaderField: "Authorization") == "Bearer pnap-access")
    }

    @Test("空发票列表是本月 $0")
    func emptyInvoicesAreZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                PhoenixNAPBillingProvider.tokenURL,
                LiveProviderHarness.json(["access_token": "t"] as [String: Any])
            ),
            (
                PhoenixNAPBillingProvider.invoicesURL(offset: 0),
                LiveProviderHarness.json([
                    "limit": 100, "offset": 0, "total": 0, "results": [] as [Any],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (PhoenixNAPBillingProvider.tokenURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (
                        PhoenixNAPBillingProvider.tokenURL,
                        LiveProviderHarness.json(["access_token": "t"] as [String: Any])
                    ),
                    (
                        PhoenixNAPBillingProvider.invoicesURL(offset: 0),
                        LiveProviderHarness.emptyJSON(status: status)
                    ),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .phoenixnap, fields: [.clientID: clientID, .clientSecret: clientSecret])
    }

    private func provider(_ client: any HTTPClient) -> PhoenixNAPBillingProvider {
        PhoenixNAPBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
