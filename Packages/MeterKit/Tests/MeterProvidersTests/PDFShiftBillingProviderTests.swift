import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PDFShiftBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "pdfshift-key-MUST-NOT-LEAK"

    @Test("本月 USD 发票合计")
    func sumsCurrentMonthInvoices() async throws {
        let url = PDFShiftBillingProvider.invoicesURL
        let august = Int64(LiveProviderHarness.date(2026, 8, 5).timeIntervalSince1970 * 1000)
        let july = Int64(LiveProviderHarness.date(2026, 7, 1).timeIntervalSince1970 * 1000)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "success": true,
                    "invoices": [
                        "data": [
                            [
                                "created": august,
                                "amount": 24,
                                "reference": "PS202608-00001",
                            ],
                            [
                                "created": july,
                                "amount": 999,
                                "reference": "PS202607-00099",
                            ],
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: 24))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == secret)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = PDFShiftBillingProvider.invoicesURL
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
        Credential(providerID: .pdfshift, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> PDFShiftBillingProvider {
        PDFShiftBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
