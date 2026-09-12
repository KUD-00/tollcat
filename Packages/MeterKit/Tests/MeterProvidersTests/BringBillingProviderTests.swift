import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct BringBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "bring-api-key-MUST-NOT-LEAK"
    private let email = "billing@example.com"
    private let customer = "CUST123"

    @Test("invoice totalAmount + currency with dd.mm.yyyy")
    func readsInvoices() async throws {
        let url = ProviderURL.https(
            host: BringBillingProvider.apiHost,
            path: "/invoicearchive/api/invoices/\(customer).json",
            query: [
                URLQueryItem(name: "fromDate", value: "01.09.2026"),
                URLQueryItem(name: "toDate", value: "30.09.2026"),
            ]
        )
        // harness now is fixed; compute expected dates from calendar window
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let from = BringBillingProvider.formatBringDate(current.start, calendar: calendar)
        let to = BringBillingProvider.formatBringDate(current.endInclusive, calendar: calendar)
        let expectedURL = ProviderURL.https(
            host: BringBillingProvider.apiHost,
            path: "/invoicearchive/api/invoices/\(customer).json",
            query: [
                URLQueryItem(name: "fromDate", value: from),
                URLQueryItem(name: "toDate", value: to),
            ]
        )
        let day = calendar.component(.day, from: current.start)
        let month = calendar.component(.month, from: current.start)
        let year = calendar.component(.year, from: current.start)
        let invoiceDate = String(format: "%02d.%02d.%04d", min(day + 5, 28), month, year)
        let client = LiveProviderHarness.stub([
            (
                expectedURL,
                LiveProviderHarness.json([
                    "status": "OK",
                    "invoices": [
                        [
                            "invoiceNumber": "10158070",
                            "invoiceDate": invoiceDate,
                            "currency": "NOK",
                            "totalAmount": "386.25",
                            "type": "Invoice",
                            "status": "Open",
                        ],
                        [
                            "invoiceNumber": "10158071",
                            "invoiceDate": invoiceDate,
                            "currency": "NOK",
                            "totalAmount": "-50.00",
                            "type": "Credit note",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "336.25")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-Mybring-API-Uid") == email)
        #expect(request.value(forHTTPHeaderField: "X-Mybring-API-Key") == secret)
        #expect(request.value(forHTTPHeaderField: "X-Bring-Client-URL") == BringBillingProvider.clientURL)
        _ = url
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let expectedURL = ProviderURL.https(
            host: BringBillingProvider.apiHost,
            path: "/invoicearchive/api/invoices/\(customer).json",
            query: [
                URLQueryItem(name: "fromDate", value: BringBillingProvider.formatBringDate(current.start, calendar: calendar)),
                URLQueryItem(name: "toDate", value: BringBillingProvider.formatBringDate(current.endInclusive, calendar: calendar)),
            ]
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(expectedURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(expectedURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .bring, fields: [
            .email: email,
            .apiKey: secret,
            .accountID: customer,
        ])
    }

    private func provider(_ client: any HTTPClient) -> BringBillingProvider {
        BringBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.passthroughRates
        )
    }
}
