import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PayPalBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let clientID = "paypal-client-MUST-NOT-LEAK"
    private let clientSecret = "paypal-secret-MUST-NOT-LEAK"

    @Test("fee_amount abs from reporting transactions")
    func readsFees() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let initiated = String(
            format: "%04d-%02d-15T12:00:00Z",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let end = min(current.nextStart, now.addingTimeInterval(1))
        let tokenURL = PayPalBillingProvider.tokenURL
        let listURL = ProviderURL.https(
            host: PayPalBillingProvider.apiHost,
            path: "/v1/reporting/transactions",
            query: [
                URLQueryItem(name: "start_date", value: PayPalBillingProvider.iso8601(current.start)),
                URLQueryItem(name: "end_date", value: PayPalBillingProvider.iso8601(end)),
                URLQueryItem(name: "fields", value: "transaction_info"),
                URLQueryItem(name: "page_size", value: "100"),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                tokenURL,
                LiveProviderHarness.json(["access_token": "pp-access-MUST-NOT-LEAK", "token_type": "Bearer"])
            ),
            (
                listURL,
                LiveProviderHarness.json([
                    "transaction_details": [
                        [
                            "transaction_info": [
                                "transaction_id": "TX1",
                                "transaction_event_code": "T0006",
                                "transaction_initiation_date": initiated,
                                "transaction_amount": ["currency_code": "EUR", "value": "105.00"],
                                "fee_amount": ["currency_code": "EUR", "value": "-0.40"],
                            ],
                        ],
                    ],
                    "total_pages": 1,
                    "page": 1,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "0.44")!))
        #expect(client.leakedSecrets([clientSecret, "pp-access-MUST-NOT-LEAK"]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let auth = try #require(client.requests.first)
        #expect(auth.url == tokenURL)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let tokenURL = PayPalBillingProvider.tokenURL
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(tokenURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(tokenURL, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .paypal, fields: [.clientID: clientID, .clientSecret: clientSecret])
    }

    private func provider(_ client: any HTTPClient) -> PayPalBillingProvider {
        PayPalBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": Decimal(string: "1.10")!]))
        )
    }
}
