import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CatalystVMBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let user = "user@example.com"
    private let eurRate = Decimal(string: "1.10")!
    private let password = "cvm-pass-MUST-NOT-LEAK"

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
                CatalystVMBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "1001",
                            "number": "2026/08/1",
                            "date": date,
                            "total": "42.50",
                            "currency": "EUR",
                            "status": "Paid",
                        ],
                        [
                            "id": "1002",
                            "number": "2026/08/2",
                            "date": date,
                            "total": "5.00",
                            "currency": "EUR",
                            "status": "Cancelled",
                        ],
                        [
                            "id": "1",
                            "number": "2020/01/1",
                            "date": "2020-01-05",
                            "total": "99.00",
                            "currency": "EUR",
                            "status": "Paid",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "46.75")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([password]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (CatalystVMBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (CatalystVMBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .catalystvm, fields: [.email: user, .clientSecret: password])
    }

    private func provider(_ client: any HTTPClient) -> CatalystVMBillingProvider {
        CatalystVMBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }
}
