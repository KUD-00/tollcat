import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PrintifyBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "printify-token-MUST-NOT-LEAK"
    private let shop = "5432"

    @Test("line_items cost+shipping cents, skip retail total_price")
    func sumsMerchantCosts() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = String(format: "%04d-%02d-10 12:00:00+00:00",
                             calendar.component(.year, from: current.start),
                             calendar.component(.month, from: current.start))
        let url = ProviderURL.https(
            host: PrintifyBillingProvider.apiHost,
            path: "/v1/shops/\(shop)/orders.json",
            query: [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "page", value: "1"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "current_page": 1,
                    "last_page": 1,
                    "data": [
                        [
                            "id": "ord_1",
                            "status": "fulfilled",
                            "created_at": created,
                            "total_price": 99999,
                            "line_items": [
                                [
                                    "cost": 1050,
                                    "shipping_cost": 400,
                                    "status": "fulfilled",
                                    "metadata": ["price": 2200],
                                ] as [String: Any],
                            ],
                        ] as [String: Any],
                        [
                            "id": "ord_hold",
                            "status": "on-hold",
                            "created_at": created,
                            "line_items": [
                                ["cost": 500, "shipping_cost": 100, "status": "on-hold"] as [String: Any],
                            ],
                        ] as [String: Any],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "14.50")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .printify, fields: [.apiKey: secret, .accountID: shop])
    }

    private func provider(_ client: any HTTPClient) -> PrintifyBillingProvider {
        PrintifyBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
