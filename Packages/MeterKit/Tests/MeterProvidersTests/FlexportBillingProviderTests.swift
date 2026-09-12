import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FlexportBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "flexport-token-MUST-NOT-LEAK"

    @Test("本月正金额发票按 currency_code 合计")
    func sumsPositiveInvoices() async throws {
        let url = FlexportBillingProvider.invoicesURL(page: 1)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        "data": [
                            [
                                "id": "inv1",
                                "name": "FLEX-1",
                                "issued_at": "2026-08-10T12:00:00Z",
                                "total": ["amount": "100.50", "currency_code": "USD"],
                                "status": "paid",
                                "type": "Shipment",
                            ],
                            [
                                "id": "inv2",
                                "name": "FLEX-2",
                                "issued_at": "2026-08-20T12:00:00Z",
                                "total": ["amount": "9.50", "currency_code": "USD"],
                                "status": "outstanding",
                                "type": "Shipment",
                            ],
                            [
                                "id": "voided",
                                "name": "FLEX-V",
                                "issued_at": "2026-08-12T12:00:00Z",
                                "total": ["amount": "50.00", "currency_code": "USD"],
                                "status": "void",
                                "type": "Shipment",
                                "voided_at": "2026-08-13T00:00:00Z",
                            ],
                            [
                                "id": "old",
                                "name": "FLEX-OLD",
                                "issued_at": "2026-07-01T12:00:00Z",
                                "total": ["amount": "999.00", "currency_code": "USD"],
                                "status": "paid",
                                "type": "Shipment",
                            ],
                        ] as [[String: Any]]
                    ] as [String: Any]
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
        #expect(request.value(forHTTPHeaderField: "Flexport-Version") == "3")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = FlexportBillingProvider.invoicesURL(page: 1)
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
        Credential(providerID: .flexport, fields: [.personalAccessToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> FlexportBillingProvider {
        FlexportBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
