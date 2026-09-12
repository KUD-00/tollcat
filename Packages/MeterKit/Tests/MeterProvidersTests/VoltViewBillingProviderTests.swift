import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct VoltViewBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "voltview-key-MUST-NOT-LEAK"

    @Test("本月 GBP totalAmount 换算合计")
    func sumsGBPInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                VoltViewBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    [
                        "documentType": "invoice",
                        "supplierName": "Acme Energy",
                        "items": [
                            [
                                "itemType": "invoice",
                                "invoiceNumber": "INV-1",
                                "invoiceDate": "2026-08-10",
                                "totalAmount": 100.0,
                                "netAmount": 80.0,
                            ],
                            [
                                "itemType": "invoice",
                                "invoiceNumber": "INV-2",
                                "invoiceDate": "2026-08-20",
                                "totalAmount": 50.0,
                            ],
                            [
                                "itemType": "credit",
                                "invoiceNumber": "CR-1",
                                "invoiceDate": "2026-08-21",
                                "totalAmount": 20.0,
                            ],
                            [
                                "itemType": "invoice",
                                "invoiceNumber": "OLD",
                                "invoiceDate": "2026-07-01",
                                "totalAmount": 999.0,
                            ],
                        ] as [[String: Any]],
                    ]
                ] as [Any])
            ),
        ])
        let rates = SharedExchangeRates(ExchangeRates(usdPerUnit: ["GBP": Decimal(string: "1.25")!]))
        let snapshot = try await VoltViewBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: rates
        ).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 150 GBP * 1.25 = 187.5 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "187.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == secret)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = VoltViewBillingProvider.invoicesURL
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
            try await VoltViewBillingProvider(
                httpClient: LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))]),
                now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .voltview, fields: [.apiKey: secret])
    }
}
