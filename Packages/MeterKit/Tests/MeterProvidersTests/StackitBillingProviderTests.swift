import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct StackitBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "stackit-token-MUST-NOT-LEAK"
    private let org = "11111111-1111-1111-1111-111111111111"

    @Test("gross + currency for current month invoices")
    func sumsGross() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let year = calendar.component(.year, from: current.start)
        let month = calendar.component(.month, from: current.start)
        let created = String(format: "%04d-%02d-12", year, month)
        let url = ProviderURL.https(
            host: StackitBillingProvider.apiHost,
            path: "/v1/organizations/\(org)/invoices",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
                URLQueryItem(name: "limit", value: "100"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "invoiceNumber": "INV-1",
                            "creationDate": created,
                            "beginDate": created,
                            "currency": "EUR",
                            "gross": 42.5,
                            "net": 35.7,
                            "documentType": "INVOICE",
                        ],
                        [
                            "invoiceNumber": "INV-2",
                            "creationDate": created,
                            "currency": "EUR",
                            "gross": 7.5,
                            "documentType": "INVOICE",
                        ],
                        [
                            "invoiceNumber": "CN-1",
                            "creationDate": created,
                            "currency": "EUR",
                            "gross": -3,
                            "documentType": "CREDIT_NOTE",
                        ],
                    ],
                    "limit": 100,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "55.00")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let year = calendar.component(.year, from: current.start)
        let month = calendar.component(.month, from: current.start)
        let url = ProviderURL.https(
            host: StackitBillingProvider.apiHost,
            path: "/v1/organizations/\(org)/invoices",
            query: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month)),
                URLQueryItem(name: "limit", value: "100"),
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
        Credential(providerID: .stackit, fields: [.apiToken: token, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> StackitBillingProvider {
        StackitBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": Decimal(string: "1.10")!]))
        )
    }
}
