import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct OcambaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "ocamba-key-MUST-NOT-LEAK"

    @Test("本月 amount+currency_code 合计")
    func sumsInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                OcambaBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "total": 3,
                    "items": [
                        [
                            "id": "1",
                            "invoice_number": "OCM-1",
                            "status": "paid",
                            "amount": 100.50,
                            "currency_code": "USD",
                            "create_time": "2026-08-10 10:00:00",
                        ],
                        [
                            "id": "2",
                            "invoice_number": "OCM-2",
                            "status": "paid",
                            "amount": 9.50,
                            "currency_code": "USD",
                            "create_time": "2026-08-15 08:00:00",
                        ],
                        [
                            "id": "old",
                            "invoice_number": "OCM-OLD",
                            "status": "paid",
                            "amount": 999.00,
                            "currency_code": "USD",
                            "create_time": "2026-07-01 08:00:00",
                        ],
                    ] as [[String: Any]],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = OcambaBillingProvider.invoicesURL
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
        Credential(providerID: .ocamba, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> OcambaBillingProvider {
        OcambaBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
