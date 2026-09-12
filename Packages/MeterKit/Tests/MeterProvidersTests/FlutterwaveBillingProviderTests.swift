import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FlutterwaveBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "FLWSECK_TEST-MUST-NOT-LEAK"

    @Test("app_fee major units from successful transactions")
    func readsFees() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = String(
            format: "%04d-%02d-11T19:33:20.000Z",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let url = ProviderURL.https(
            host: FlutterwaveBillingProvider.apiHost,
            path: "/v3/transactions",
            query: [
                URLQueryItem(name: "from", value: FlutterwaveBillingProvider.dateOnly(current.start)),
                URLQueryItem(name: "to", value: FlutterwaveBillingProvider.dateOnly(current.nextStart)),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "status": "success",
                    "message": "Transactions fetched",
                    "data": [
                        [
                            "id": 1163077,
                            "tx_ref": "akhlm-pstmn-23452",
                            "status": "successful",
                            "currency": "USD",
                            "payment_type": "card",
                            "app_fee": 14,
                            "created_at": created,
                        ],
                    ],
                    "meta": ["page_info": ["total_pages": 1, "current_page": 1]],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "14")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let url = ProviderURL.https(
            host: FlutterwaveBillingProvider.apiHost,
            path: "/v3/transactions",
            query: [
                URLQueryItem(name: "from", value: FlutterwaveBillingProvider.dateOnly(current.start)),
                URLQueryItem(name: "to", value: FlutterwaveBillingProvider.dateOnly(current.nextStart)),
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
        Credential(providerID: .flutterwave, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> FlutterwaveBillingProvider {
        FlutterwaveBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
