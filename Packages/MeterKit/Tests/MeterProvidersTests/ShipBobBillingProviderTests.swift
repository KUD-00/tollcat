import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ShipBobBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "shipbob-pat-MUST-NOT-LEAK"

    @Test("本月正金额发票按 currency_code 合计")
    func sumsPositiveInvoices() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ShipBobBillingProvider.invoicesURL(from: window.start, to: window.endInclusive, page: 1)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "items": [
                        [
                            "invoice_id": 1,
                            "invoice_date": "2026-08-10",
                            "invoice_type": "Shipping",
                            "amount": 6.93,
                            "currency_code": "USD",
                        ],
                        [
                            "invoice_id": 2,
                            "invoice_date": "2026-08-10",
                            "invoice_type": "CreditCardProcessingFee",
                            "amount": 0.21,
                            "currency_code": "USD",
                        ],
                        [
                            "invoice_id": 3,
                            "invoice_date": "2026-08-10",
                            "invoice_type": "Payment",
                            "amount": -7.14,
                            "currency_code": "USD",
                        ],
                        [
                            "invoice_id": 4,
                            "invoice_date": "2026-07-01",
                            "invoice_type": "Shipping",
                            "amount": 99.0,
                            "currency_code": "USD",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "7.14")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ShipBobBillingProvider.invoicesURL(from: window.start, to: window.endInclusive, page: 1)
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
        Credential(providerID: .shipbob, fields: [.personalAccessToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> ShipBobBillingProvider {
        ShipBobBillingProvider(httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates())
    }
}
