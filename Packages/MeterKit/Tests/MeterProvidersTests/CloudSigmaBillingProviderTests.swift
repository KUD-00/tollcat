import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CloudSigmaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let token = "cs-pass-MUST-NOT-LEAK"
    private let host = "zrh.cloudsigma.com"

    @Test("positive ledger amounts; ignore top-up negatives")
    func sumsLedger() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let stamp = String(
            format: "%04d-%02d-10T12:00:00+00:00",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                CloudSigmaBillingProvider.balanceURL(host: host),
                LiveProviderHarness.json([
                    "balance": "100.00",
                    "currency": "CHF",
                ] as [String: Any])
            ),
            (
                CloudSigmaBillingProvider.ledgerURL(host: host, offset: 0),
                LiveProviderHarness.json([
                    "meta": ["limit": 100, "offset": 0, "total_count": 3],
                    "objects": [
                        [
                            "id": "1",
                            "amount": "12.50",
                            "reason": "Burst CPU",
                            "time": stamp,
                        ],
                        [
                            "id": "2",
                            "amount": "-50.00",
                            "reason": "Card top-up",
                            "time": stamp,
                        ],
                        [
                            "id": "3",
                            "amount": "1.25",
                            "reason": "Old",
                            "time": "2020-01-01T00:00:00+00:00",
                        ],
                    ],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.converted != nil)
        #expect(client.leakedSecrets([token]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (CloudSigmaBillingProvider.balanceURL(host: host), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (CloudSigmaBillingProvider.balanceURL(host: host), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .cloudsigma,
            fields: [.email: "user@example.com", .apiKey: token, .projectID: host]
        )
    }

    private func provider(_ client: any HTTPClient) -> CloudSigmaBillingProvider {
        CloudSigmaBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["CHF": Decimal(string: "1.12")!]))
        )
    }
}
