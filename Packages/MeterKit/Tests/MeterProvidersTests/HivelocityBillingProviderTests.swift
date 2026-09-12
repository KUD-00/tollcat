import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct HivelocityBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let key = "hv-key-MUST-NOT-LEAK"

    @Test("amount USD; skip cancelled; ignore unpaid/credit")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = Int(current.start.addingTimeInterval(5 * 86400).timeIntervalSince1970)
        let client = LiveProviderHarness.stub([
            (
                HivelocityBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    [
                        "id": 101,
                        "amount": 42.5,
                        "status": "Paid",
                        "created": created,
                    ],
                    [
                        "id": 102,
                        "amount": 9.0,
                        "status": "Cancelled",
                        "created": created,
                    ],
                    [
                        "id": 1,
                        "amount": 99.0,
                        "status": "Paid",
                        "created": 1_578_000_000,
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(client.leakedSecrets([key]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (HivelocityBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (HivelocityBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .hivelocity, fields: [.apiKey: key])
    }

    private func provider(_ client: any HTTPClient) -> HivelocityBillingProvider {
        HivelocityBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
