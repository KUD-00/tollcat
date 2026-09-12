import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct Time4VPSBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let user = "user@example.com"
    private let password = "t4v-pass-MUST-NOT-LEAK"

    @Test("total + currency; skip cancelled; ignore balance")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-05",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                Time4VPSBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": 308976,
                            "number": "2026/08/1",
                            "date": date,
                            "total": "19.65",
                            "currency": "USD",
                            "status": "Paid",
                        ],
                        [
                            "id": 308977,
                            "number": "2026/08/2",
                            "date": date,
                            "total": "5.00",
                            "currency": "USD",
                            "status": "Cancelled",
                        ],
                        [
                            "id": 1,
                            "number": "2020/01/1",
                            "date": "2020-01-05",
                            "total": "99.00",
                            "currency": "USD",
                            "status": "Paid",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "19.65")!))
        #expect(client.leakedSecrets([password]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (Time4VPSBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (Time4VPSBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .time4vps,
            fields: [.email: user, .clientSecret: password]
        )
    }

    private func provider(_ client: any HTTPClient) -> Time4VPSBillingProvider {
        Time4VPSBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
