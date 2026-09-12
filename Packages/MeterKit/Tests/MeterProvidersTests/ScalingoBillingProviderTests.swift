import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ScalingoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiToken = "tk-us-SCALINGO-MUST-NOT-LEAK"
    private let bearer = "bearer-scalingo-FIXTURE"
    private let euroRate = Decimal(string: "1.10")!

    @Test("exchange token then sum EUR-cent invoices; skip failed")
    func sumsInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                ScalingoBillingProvider.exchangeURL,
                LiveProviderHarness.json(["token": bearer])
            ),
            (
                ScalingoBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "inv-1",
                            "invoice_number": "2026-08-1",
                            "billing_month": "2026-08-01",
                            "total_price": 1000,
                            "total_price_with_vat": 1200,
                            "state": "paid",
                        ],
                        [
                            "id": "inv-fail",
                            "invoice_number": "2026-08-2",
                            "billing_month": "2026-08-01",
                            "total_price": 500,
                            "total_price_with_vat": 600,
                            "state": "failed",
                        ],
                        [
                            "id": "inv-old",
                            "invoice_number": "2026-07-1",
                            "billing_month": "2026-07-01",
                            "total_price": 9000,
                            "total_price_with_vat": 10800,
                            "state": "paid",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 12.00 EUR * 1.10 = 13.20 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.2")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([apiToken]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let exchange = try #require(client.requests.first)
        #expect(exchange.httpMethod == "POST")
        #expect(
            exchange.value(forHTTPHeaderField: "Authorization")
            == "Basic \(ProviderOAuth.basicValue(id: "", secret: apiToken))"
        )
        let invoices = try #require(client.requests.last)
        #expect(invoices.value(forHTTPHeaderField: "Authorization") == "Bearer \(bearer)")
    }

    @Test("401 / 403 on invoices")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (ScalingoBillingProvider.exchangeURL, LiveProviderHarness.json(["token": bearer])),
                    (ScalingoBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (ScalingoBillingProvider.exchangeURL, LiveProviderHarness.json(["token": bearer])),
                    (ScalingoBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .scalingo, fields: [.apiToken: apiToken])
    }

    private func provider(_ client: any HTTPClient) -> ScalingoBillingProvider {
        ScalingoBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
