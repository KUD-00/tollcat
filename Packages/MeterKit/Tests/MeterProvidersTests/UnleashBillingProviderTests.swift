import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct UnleashBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "unleash-token-MUST-NOT-LEAK"
    private let host = "eu.app.unleash-hosted.com"

    @Test("totalAmount + currency; skip void")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-01T00:00:00.000Z",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                UnleashBillingProvider.invoicesURL(host: host),
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "invoiceDate": date,
                            "status": "paid",
                            "totalAmount": 80,
                            "currency": "usd",
                            "monthText": "Current",
                        ],
                        [
                            "invoiceDate": date,
                            "status": "void",
                            "totalAmount": 40,
                            "currency": "usd",
                            "monthText": "Void",
                        ],
                        [
                            "invoiceDate": "2020-01-01T00:00:00.000Z",
                            "status": "paid",
                            "totalAmount": 99,
                            "currency": "usd",
                            "monthText": "Old",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "80")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (UnleashBillingProvider.invoicesURL(host: host), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (UnleashBillingProvider.invoicesURL(host: host), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .unleash, fields: [.apiToken: token, .projectID: host])
    }

    private func provider(_ client: any HTTPClient) -> UnleashBillingProvider {
        UnleashBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
