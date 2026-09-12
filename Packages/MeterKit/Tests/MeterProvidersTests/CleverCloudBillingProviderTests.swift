import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CleverCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "clever-token-MUST-NOT-LEAK"
    private let org = "org_demo"
    private let euroRate = Decimal(string: "1.10")!

    @Test("本月 EUR 发票合计")
    func sumsCurrentMonthInvoices() async throws {
        let url = CleverCloudBillingProvider.invoicesURL(orgID: org)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    [
                        "invoice_number": "INV-1",
                        "emission_date": "2026-08-05",
                        "currency": "EUR",
                        "total_tax_excluded": ["currency": "EUR", "amount": 100.0],
                        "total_tax": ["currency": "EUR", "amount": 20.0],
                    ],
                    [
                        "invoice_number": "OLD",
                        "emission_date": "2026-07-01",
                        "currency": "EUR",
                        "total_tax_excluded": ["currency": "EUR", "amount": 999.0],
                        "total_tax": ["currency": "EUR", "amount": 0.0],
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 120 EUR * 1.10 = 132 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "132")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = CleverCloudBillingProvider.invoicesURL(orgID: org)
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
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .clevercloud, fields: [.apiToken: secret, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> CleverCloudBillingProvider {
        CleverCloudBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
