import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FormspringBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "fs-token-MUST-NOT-LEAK"

    @Test("USD cents total; skip void")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-01T00:00:12+00:00",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                FormspringBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": "in_1",
                            "number": "ACME-2026-0007",
                            "total": 4900,
                            "status": "paid",
                            "date": date,
                        ],
                        [
                            "id": "in_2",
                            "number": "ACME-void",
                            "total": 1200,
                            "status": "void",
                            "date": date,
                        ],
                        [
                            "id": "in_old",
                            "number": "ACME-2020",
                            "total": 9900,
                            "status": "paid",
                            "date": "2020-01-01T00:00:00+00:00",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "49")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (FormspringBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (FormspringBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .formspring, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> FormspringBillingProvider {
        FormspringBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
