import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct SendcloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let publicKey = "sc_public_MUST_NOT_LEAK_abc123"
    private let privateKey = "sc_secret_MUST_NOT_LEAK_def456"
    private let eurRate = Decimal(string: "1.10")!

    @Test("本月 invoice price_*+tax value+currency 合计；忽略窗外")
    func sumsInvoices() async throws {
        let url = SendcloudBillingProvider.invoicesURL(cursor: nil)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": 5501,
                            "reference": "INV-2026-000123",
                            "created_at": "2026-08-10T00:00:00Z",
                            "due_date": "2026-09-10T00:00:00Z",
                            "price_taxable": ["value": "100.0000", "currency": "EUR"],
                            "price_non_taxable": ["value": "0.0000", "currency": "EUR"],
                            "tax": ["value": "21.0000", "currency": "EUR"],
                            "description": "Shipping charges — August 2026",
                            "category": "transactional",
                        ],
                        [
                            "id": 5480,
                            "reference": "INV-2026-000099",
                            "created_at": "2026-08-01T00:00:00Z",
                                                        "price_taxable": ["value": "49.0000", "currency": "EUR"],
                                                        "tax": ["value": "10.2900", "currency": "EUR"],
                            "description": "Subscription — August 2026",
                            "category": "subscription",
                        ],
                        [
                            "id": 5400,
                            "reference": "INV-2026-000050",
                            "created_at": "2026-07-05T00:00:00Z",
                            "price_taxable": ["value": "80.0000", "currency": "EUR"],
                                                        "tax": ["value": "16.8000", "currency": "EUR"],
                            "description": "July",
                            "category": "transactional",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // (100+0+21) + (49+10.29) = 180.29 * 1.10 = 198.319 → 198.32
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "198.32")!))
        #expect(client.leakedSecrets([privateKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.httpMethod == "GET")
        let expected = "Basic \(ProviderOAuth.basicValue(id: publicKey, secret: privateKey))"
        #expect(request.value(forHTTPHeaderField: "Authorization") == expected)
        #expect(request.url?.absoluteString.contains("page_size=100") == true)
    }

    @Test("Link rel=next 翻页取 cursor")
    func followsLinkCursor() async throws {
        let page1 = SendcloudBillingProvider.invoicesURL(cursor: nil)
        let page2 = SendcloudBillingProvider.invoicesURL(cursor: "cj0xJnA9MzAw")
        let link = "<\(page2.absoluteString)>; rel=\"next\""
        let client = LiveProviderHarness.stub([
            (
                page1,
                LiveProviderHarness.json(
                    [
                        "data": [
                            [
                                "id": 1,
                                "reference": "A",
                                "created_at": "2026-08-12T00:00:00Z",
                                "price_taxable": ["value": "10.0000", "currency": "EUR"],
                                                                "tax": ["value": "0.0000", "currency": "EUR"],
                                "description": "p1",
                                "category": "transactional",
                            ],
                        ],
                    ] as [String: Any],
                    headers: ["Link": link]
                )
            ),
            (
                page2,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": 2,
                            "reference": "B",
                            "created_at": "2026-08-11T00:00:00Z",
                            "price_taxable": ["value": "5.0000", "currency": "EUR"],
                                                        "tax": ["value": "0.0000", "currency": "EUR"],
                            "description": "p2",
                            "category": "subscription",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        // (10 + 5) * 1.10 = 16.5
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "16.50")!))
        #expect(client.requests.count == 2)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = SendcloudBillingProvider.invoicesURL(cursor: nil)
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials, url: url)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions, url: url)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        url: URL
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (url, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .sendcloud, fields: [
            .apiKey: publicKey,
            .clientSecret: privateKey,
        ])
    }

    private func provider(_ client: any HTTPClient) -> SendcloudBillingProvider {
        SendcloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }
}
