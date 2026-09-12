import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PleoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "pls_test_key_MUST-NOT-LEAK"
    private let companyID = "12abc3d4-e567-890e-1234-abc56e78fabc"

    @Test("本月 PLEO_INVOICE minors/100 合计，跳过 CANCELLED，退款记负")
    func sumsPleoInvoices() async throws {
        let url = PleoBillingProvider.searchURL(companyID: companyID, after: nil)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": "inv-1",
                            "family": "PLEO_INVOICE",
                            "subFamily": "PLEO_INVOICE",
                            "status": "COMPLETED",
                            "performedAt": "2026-08-10T10:00:00.000Z",
                            "transactionValue": ["currency": "USD", "minors": 9900],
                        ],
                        [
                            "id": "inv-2",
                            "family": "PLEO_INVOICE",
                            "status": "COMPLETED",
                            "performedAt": "2026-08-15T10:00:00.000Z",
                            "transactionValue": ["currency": "USD", "minors": 2500],
                        ],
                        [
                            "id": "inv-void",
                            "family": "PLEO_INVOICE",
                            "status": "CANCELLED",
                            "performedAt": "2026-08-12T10:00:00.000Z",
                            "transactionValue": ["currency": "USD", "minors": 5000],
                        ],
                        [
                            "id": "inv-refund",
                            "family": "PLEO_INVOICE",
                            "subFamily": "PLEO_INVOICE_REFUND",
                            "status": "COMPLETED",
                            "performedAt": "2026-08-18T10:00:00.000Z",
                            "transactionValue": ["currency": "USD", "minors": 1000],
                        ],
                        [
                            "id": "inv-july",
                            "family": "PLEO_INVOICE",
                            "status": "COMPLETED",
                            "performedAt": "2026-07-05T10:00:00.000Z",
                            "transactionValue": ["currency": "USD", "minors": 8000],
                        ],
                    ],
                    "pagination": ["hasNextPage": false],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 99.00 + 25.00 - 10.00 = 114.00
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "114")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Basic \(ProviderOAuth.basicValue(id: secret, secret: ""))"
        )
        let body = try #require(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["includeDeleted"] as? Bool == false)
        #expect(json?["families"] as? [String] == ["PLEO_INVOICE"])
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = PleoBillingProvider.searchURL(companyID: companyID, after: nil)
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
        Credential(providerID: .pleo, fields: [.apiKey: secret, .accountID: companyID])
    }

    private func provider(_ client: any HTTPClient) -> PleoBillingProvider {
        PleoBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
