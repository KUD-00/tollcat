import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FrankEnergieBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "frank-token-MUST-NOT-LEAK"
    private let site = "1000AA 101"
    private let eurRate = Decimal(string: "1.10")!

    @Test("allInvoices totalAmount EUR")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let date = String(
            format: "%04d-%02d-10",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                FrankEnergieBillingProvider.graphqlURL,
                LiveProviderHarness.json([
                    "data": [
                        "invoices": [
                            "allInvoices": [
                                [
                                    "id": "inv-1",
                                    "invoiceDate": date,
                                    "startDate": date,
                                    "periodDescription": "Aug 2026",
                                    "totalAmount": 100.0,
                                ],
                                [
                                    "id": "inv-old",
                                    "invoiceDate": "2020-01-01",
                                    "startDate": "2020-01-01",
                                    "totalAmount": 50.0,
                                ],
                            ]
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "110.00")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (FrankEnergieBillingProvider.graphqlURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (FrankEnergieBillingProvider.graphqlURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .frankenergie, fields: [.apiToken: token, .accountID: site])
    }

    private func provider(_ client: any HTTPClient) -> FrankEnergieBillingProvider {
        FrankEnergieBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": eurRate]))
        )
    }
}
