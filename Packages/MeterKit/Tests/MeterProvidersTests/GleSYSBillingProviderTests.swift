import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GleSYSBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "glesys-key-MUST-NOT-LEAK"
    private let customer = "12345"

    @Test("response.invoices total+currency")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-05",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                GleSYSBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "response": [
                        "invoices": [
                            [
                                "invoicenumber": 1001,
                                "invoicedate": date,
                                "total": 420.5,
                                "currency": "SEK",
                                "url": "invoice-1001",
                            ],
                            [
                                "invoicenumber": 900,
                                "invoicedate": "2020-01-01",
                                "total": 99,
                                "currency": "SEK",
                            ],
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.converted != nil)
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (GleSYSBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (GleSYSBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .glesys, fields: [.accountID: customer, .apiKey: token])
    }

    private func provider(_ client: any HTTPClient) -> GleSYSBillingProvider {
        GleSYSBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["SEK": Decimal(string: "0.095")!]))
        )
    }
}
