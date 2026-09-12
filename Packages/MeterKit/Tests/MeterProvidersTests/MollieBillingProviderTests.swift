import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MollieBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "access_mollie-MUST-NOT-LEAK"

    @Test("grossAmount EUR from embedded invoices")
    func readsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let issued = String(format: "%04d-%02d-15",
                            calendar.component(.year, from: current.start),
                            calendar.component(.month, from: current.start))
        let url = ProviderURL.https(
            host: MollieBillingProvider.apiHost,
            path: "/v2/invoices",
            query: [URLQueryItem(name: "limit", value: "250")]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "count": 1,
                    "_embedded": [
                        "invoices": [
                            [
                                "resource": "invoice",
                                "id": "inv_xBEbP9rvAq",
                                "reference": "2026.10000",
                                "status": "open",
                                "issuedAt": issued,
                                "grossAmount": ["currency": "EUR", "value": "54.45"],
                                "netAmount": ["currency": "EUR", "value": "45.00"],
                                "lines": [
                                    [
                                        "period": String(issued.prefix(7)),
                                        "description": "iDEAL fees",
                                        "count": 100,
                                        "vatPercentage": 21,
                                        "amount": ["currency": "EUR", "value": "45.00"],
                                    ],
                                ],
                            ],
                        ],
                    ] as [String: Any],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "54.45")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = ProviderURL.https(
            host: MollieBillingProvider.apiHost,
            path: "/v2/invoices",
            query: [URLQueryItem(name: "limit", value: "250")]
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
        Credential(providerID: .mollie, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MollieBillingProvider {
        MollieBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.passthroughRates
        )
    }
}
