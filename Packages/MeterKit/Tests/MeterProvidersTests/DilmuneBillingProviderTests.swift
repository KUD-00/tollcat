import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DilmuneBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "dcs_test_MUST-NOT-LEAK"

    @Test("amount cents + currency; skip void")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let iso = ISO8601DateFormatter().string(from: current.start.addingTimeInterval(86400 * 3))
        let url = ProviderURL.https(
            host: DilmuneBillingProvider.apiHost,
            path: "/api/v1/invoices",
            query: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "per_page", value: "50"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "success": true,
                    "data": [
                        [
                            "id": "inv-1",
                            "stripeInvoiceId": "in_1",
                            "amount": 42050,
                            "currency": "usd",
                            "status": "paid",
                            "periodStart": iso,
                        ],
                        [
                            "id": "inv-void",
                            "amount": 99900,
                            "currency": "usd",
                            "status": "void",
                            "periodStart": iso,
                        ],
                        [
                            "id": "inv-old",
                            "amount": 10000,
                            "currency": "usd",
                            "status": "paid",
                            "periodStart": "2020-01-01T00:00:00Z",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "420.50")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: DilmuneBillingProvider.apiHost,
            path: "/api/v1/invoices",
            query: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "per_page", value: "50"),
            ]
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .dilmune, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> DilmuneBillingProvider {
        DilmuneBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
