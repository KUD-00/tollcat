import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PaystackBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk_test_paystack-MUST-NOT-LEAK"

    @Test("fees subunits /100 from successful transactions")
    func readsFees() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let paid = String(
            format: "%04d-%02d-15T14:21:32.000Z",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let url = ProviderURL.https(
            host: PaystackBillingProvider.apiHost,
            path: "/transaction",
            query: [
                URLQueryItem(name: "status", value: "success"),
                URLQueryItem(name: "from", value: PaystackBillingProvider.iso8601(current.start)),
                URLQueryItem(name: "to", value: PaystackBillingProvider.iso8601(current.nextStart)),
                URLQueryItem(name: "perPage", value: "50"),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "status": true,
                    "message": "Transactions retrieved",
                    "data": [
                        [
                            "id": 2009945086,
                            "status": "success",
                            "reference": "rd0bz6z2wu",
                            "channel": "card",
                            "currency": "USD",
                            "fees": 100,
                            "paid_at": paid,
                            "created_at": paid,
                        ],
                    ],
                    "meta": ["page": 1, "pageCount": 1, "perPage": 50],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1.00")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ProviderURL.https(
            host: PaystackBillingProvider.apiHost,
            path: "/transaction",
            query: [
                URLQueryItem(name: "status", value: "success"),
                URLQueryItem(name: "from", value: PaystackBillingProvider.iso8601(current.start)),
                URLQueryItem(name: "to", value: PaystackBillingProvider.iso8601(current.nextStart)),
                URLQueryItem(name: "perPage", value: "50"),
                URLQueryItem(name: "page", value: "1"),
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
        Credential(providerID: .paystack, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> PaystackBillingProvider {
        PaystackBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
