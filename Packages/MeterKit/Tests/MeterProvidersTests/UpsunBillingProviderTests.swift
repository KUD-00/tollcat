import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct UpsunBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiToken = "upsun-api-token-MUST-NOT-LEAK"
    private let org = "org_demo_upsun"
    private let bearer = "upsun-bearer-FIXTURE"
    private let euroRate = Decimal(string: "1.10")!

    @Test("oauth api_token then sum order total+currency; skip canceled")
    func sumsOrders() async throws {
        let client = LiveProviderHarness.stub([
            (
                UpsunBillingProvider.tokenURL,
                LiveProviderHarness.json(["access_token": bearer, "token_type": "bearer", "expires_in": 900])
            ),
            (
                UpsunBillingProvider.ordersURL(orgID: org),
                LiveProviderHarness.json([
                    "items": [
                        [
                            "id": "ord-1",
                            "status": "completed",
                            "total": 50.0,
                            "currency": "EUR",
                            "billing_period_start": "2026-08-01T00:00:00+00:00",
                            "billing_period_end": "2026-08-31T23:59:59+00:00",
                            "billing_period_label": ["formatted": "August 2026", "month": "August", "year": "2026"],
                            "invoiced": true,
                        ],
                        [
                            "id": "ord-cancel",
                            "status": "canceled",
                            "total": 99.0,
                            "currency": "EUR",
                            "billing_period_start": "2026-08-01T00:00:00+00:00",
                        ],
                        [
                            "id": "ord-old",
                            "status": "completed",
                            "total": 40.0,
                            "currency": "EUR",
                            "billing_period_start": "2026-07-01T00:00:00+00:00",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 50 EUR * 1.10 = 55 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "55")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([apiToken]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let tokenReq = try #require(client.requests.first)
        #expect(tokenReq.httpMethod == "POST")
        #expect(
            tokenReq.value(forHTTPHeaderField: "Authorization")
            == "Basic \(ProviderOAuth.basicValue(id: UpsunBillingProvider.oauthClientID, secret: ""))"
        )
        let body = String(data: tokenReq.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("grant_type=api_token"))
        #expect(body.contains("api_token="))
        let orders = try #require(client.requests.last)
        #expect(orders.value(forHTTPHeaderField: "Authorization") == "Bearer \(bearer)")
    }

    @Test("401 / 403 on orders")
    func statusMapping() async {
        let url = UpsunBillingProvider.ordersURL(orgID: org)
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (UpsunBillingProvider.tokenURL, LiveProviderHarness.json(["access_token": bearer])),
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (UpsunBillingProvider.tokenURL, LiveProviderHarness.json(["access_token": bearer])),
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .upsun, fields: [.apiToken: apiToken, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> UpsunBillingProvider {
        UpsunBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
