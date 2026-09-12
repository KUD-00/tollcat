import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MelbicomBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "melbicom-token-MUST-NOT-LEAK"

    @Test("total + currency; skip cancelled/refunded")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-05",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                MelbicomBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    [
                        "id": 36,
                        "invoicenum": "INV-Paid",
                        "date": date,
                        "total": "10.00",
                        "currency": "USD",
                        "status": "Paid",
                    ],
                    [
                        "id": 51,
                        "invoicenum": "INV-Blank",
                        "date": date,
                        "total": "9.00",
                        "currency": "USD",
                        "status": "Cancelled",
                    ],
                    [
                        "id": 58,
                        "invoicenum": "INV-Refunded",
                        "date": date,
                        "total": "8.00",
                        "currency": "USD",
                        "status": "Refunded",
                    ],
                    [
                        "id": 99,
                        "invoicenum": "INV-Old",
                        "date": "2020-01-05",
                        "total": "50.00",
                        "currency": "USD",
                        "status": "Paid",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (MelbicomBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (MelbicomBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .melbicom,
            fields: [.apiToken: token]
        )
    }

    private func provider(_ client: any HTTPClient) -> MelbicomBillingProvider {
        MelbicomBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
