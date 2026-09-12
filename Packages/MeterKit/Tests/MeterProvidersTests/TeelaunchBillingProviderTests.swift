import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TeelaunchBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "teelaunch-jwt-MUST-NOT-LEAK"

    @Test("payment-history amount this month")
    func sumsPayments() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = String(format: "%04d-%02d-12T02:36:13.000000Z",
                             calendar.component(.year, from: current.start),
                             calendar.component(.month, from: current.start))
        let url = ProviderURL.https(
            host: TeelaunchBillingProvider.apiHost,
            path: "/api/v1/account/payment-history",
            query: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": 90,
                            "amount": "16.50",
                            "currency": "USD",
                            "status": 1,
                            "createdAt": created,
                        ] as [String: Any],
                        [
                            "id": 91,
                            "amount": "10.00",
                            "currency": "USD",
                            "status": 1,
                            "createdAt": "2020-01-01T00:00:00.000000Z",
                        ] as [String: Any],
                    ],
                    "meta": ["last_page": 1],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "16.50")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .teelaunch, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> TeelaunchBillingProvider {
        TeelaunchBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
