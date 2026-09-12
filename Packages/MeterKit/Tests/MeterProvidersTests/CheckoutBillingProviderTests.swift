import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CheckoutBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "sk_checkout-MUST-NOT-LEAK"

    @Test("processing_fees abs + payout_fee from statements")
    func readsFees() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let day = String(format: "%04d-%02d-15T12:00:00.000",
                         calendar.component(.year, from: current.start),
                         calendar.component(.month, from: current.start))
        let from = CheckoutBillingProvider.iso8601(current.start)
        // spanning for currentMonth uses current window — match what provider builds
        let fetchWindow = CalendarMonthWindow.spanning(
            for: .currentMonth,
            lookbackMonths: CheckoutBillingProvider.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let url = ProviderURL.https(
            host: CheckoutBillingProvider.apiHost,
            path: "/reporting/statements",
            query: [
                URLQueryItem(name: "from", value: CheckoutBillingProvider.iso8601(fetchWindow.start)),
                URLQueryItem(name: "to", value: CheckoutBillingProvider.iso8601(current.nextStart)),
                URLQueryItem(name: "include", value: "payout_breakdown"),
                URLQueryItem(name: "limit", value: "50"),
            ]
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "count": 1,
                    "data": [
                        [
                            "id": "190110B107654",
                            "period_start": day,
                            "period_end": day,
                            "date": day,
                            "payouts": [
                                [
                                    "currency": "GBP",
                                    "date": day,
                                    "period_start": day,
                                    "id": "ABCDEFGH",
                                    "payout_fee": -5,
                                    "current_period_breakdown": [
                                        "processing_fees": -235.78,
                                        "admin_fees": 0,
                                        "tax": 0,
                                    ],
                                ] as [String: Any],
                            ],
                        ] as [String: Any],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // abs(235.78)+abs(5)=240.78 GBP * 1.25 = 300.975 → cents round
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "300.98")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        _ = from
    }

    @Test("401 / 403")
    func statusMapping() async {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let fetchWindow = CalendarMonthWindow.spanning(
            for: .currentMonth,
            lookbackMonths: CheckoutBillingProvider.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let url = ProviderURL.https(
            host: CheckoutBillingProvider.apiHost,
            path: "/reporting/statements",
            query: [
                URLQueryItem(name: "from", value: CheckoutBillingProvider.iso8601(fetchWindow.start)),
                URLQueryItem(name: "to", value: CheckoutBillingProvider.iso8601(current.nextStart)),
                URLQueryItem(name: "include", value: "payout_breakdown"),
                URLQueryItem(name: "limit", value: "50"),
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
        Credential(providerID: .checkout, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> CheckoutBillingProvider {
        CheckoutBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["GBP": Decimal(string: "1.25")!]))
        )
    }
}
