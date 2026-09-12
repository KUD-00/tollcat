import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DoitBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "doit_token_MUST-NOT-LEAK"

    @Test("totalAmount + currency; ignore balanceAmount")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let ms = Int(current.start.addingTimeInterval(86400 * 4).timeIntervalSince1970 * 1000)
        let url = DoitBillingProvider.invoicesURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "IN1",
                            "invoiceDate": ms,
                            "platform": "amazon-web-services",
                            "totalAmount": 100.25,
                            "balanceAmount": 999.0,
                            "currency": "USD",
                            "status": "PAID",
                        ],
                        [
                            "id": "IN-old",
                            "invoiceDate": 1_577_836_800_000,
                            "totalAmount": 50.0,
                            "currency": "USD",
                            "status": "PAID",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "100.25")!))
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = DoitBillingProvider.invoicesURL
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
        Credential(providerID: .doit, fields: [.apiToken: token])
    }

    private func provider(_ client: any HTTPClient) -> DoitBillingProvider {
        DoitBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
