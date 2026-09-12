import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CUDOComputeBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "cudo-token-MUST-NOT-LEAK"
    private let account = "ba-test-001"

    @Test("本月 total 分金额按 currency 合计")
    func sumsCents() async throws {
        let url = CUDOComputeBillingProvider.invoicesURL
        // Provider builds query — match by host/path prefix via RecordingHTTPClient stub exact URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: account),
            URLQueryItem(name: "pageSize", value: "100"),
        ]
        let listURL = components.url!
        let client = LiveProviderHarness.stub([
            (
                listURL,
                LiveProviderHarness.json([
                    "hasMore": false,
                    "invoices": [
                        [
                            "id": "in_1",
                            "number": "INV-1",
                            "total": "1210",
                            "currency": "usd",
                            "created": "1786320000",
                            "status": "paid",
                            "billingReason": "subscription_cycle",
                        ],
                        [
                            "id": "in_2",
                            "number": "INV-2",
                            "total": "605",
                            "currency": "usd",
                            "created": "1786752000",
                            "status": "open",
                        ],
                        [
                            "id": "void",
                            "number": "INV-V",
                            "total": "500",
                            "currency": "usd",
                            "created": "1786320000",
                            "status": "void",
                        ],
                        [
                            "id": "old",
                            "number": "INV-OLD",
                            "total": "99900",
                            "currency": "usd",
                            "created": "1782864000",
                            "status": "paid",
                        ],
                    ] as [[String: Any]]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "18.15")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        var components = URLComponents(url: CUDOComputeBillingProvider.invoicesURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: account),
            URLQueryItem(name: "pageSize", value: "100"),
        ]
        let url = components.url!
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
        Credential(providerID: .cudocompute, fields: [.apiKey: secret, .accountID: account])
    }

    private func provider(_ client: any HTTPClient) -> CUDOComputeBillingProvider {
        CUDOComputeBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
