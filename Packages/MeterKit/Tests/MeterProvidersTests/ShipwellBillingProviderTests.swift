import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ShipwellBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "shipwell-token-MUST-NOT-LEAK"

    @Test("本月正金额按 total_amount.currency 合计，跳过 VOIDED")
    func sumsFreightInvoices() async throws {
        let url = ShipwellBillingProvider.invoicesURL(page: 1)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": "fi1",
                            "invoice_number": "SW-1",
                            "invoice_date": "2026-08-10",
                            "status": "PAID",
                            "total_amount": ["value": "100.50", "currency": "USD"],
                        ],
                        [
                            "id": "fi2",
                            "invoice_number": "SW-2",
                            "invoice_date": "2026-08-15",
                            "status": "APPROVED",
                            "total_amount": ["value": "9.50", "currency": "USD"],
                        ],
                        [
                            "id": "voided",
                            "invoice_number": "SW-V",
                            "invoice_date": "2026-08-12",
                            "status": "VOIDED",
                            "total_amount": ["value": "50.00", "currency": "USD"],
                        ],
                        [
                            "id": "old",
                            "invoice_number": "SW-OLD",
                            "invoice_date": "2026-07-01",
                            "status": "PAID",
                            "total_amount": ["value": "999.00", "currency": "USD"],
                        ],
                    ] as [[String: Any]],
                    "count": 4,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Token \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ShipwellBillingProvider.invoicesURL(page: 1)
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
        Credential(providerID: .shipwell, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ShipwellBillingProvider {
        ShipwellBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
