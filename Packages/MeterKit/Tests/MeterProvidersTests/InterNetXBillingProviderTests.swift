import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct InterNetXBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let username = "ix-user-MUST-NOT-LEAK"
    private let password = "ix-pass-MUST-NOT-LEAK"

    @Test("amount + vatAmount EUR from invoice search")
    func sumsInvoices() async throws {
        let current = CalendarMonthWindow.current(now: now, calendar: calendar)
        let created = String(
            format: "%04d-%02d-07T04:00:57.000+0000",
            calendar.component(.year, from: current.start),
            calendar.component(.month, from: current.start)
        )
        let client = LiveProviderHarness.stub([
            (
                InterNetXBillingProvider.searchURL,
                LiveProviderHarness.json([
                    "data": [
                        [
                            "id": 441,
                            "number": "40000017",
                            "amount": 10.0,
                            "vatAmount": 1.9,
                            "currency": "EUR",
                            "type": "INVOICE",
                            "failed": false,
                            "created": created,
                        ],
                        [
                            "id": 442,
                            "number": "credit",
                            "amount": 99.0,
                            "vatAmount": 0,
                            "currency": "EUR",
                            "type": "CREDIT",
                            "failed": false,
                            "created": created,
                        ],
                        [
                            "id": 443,
                            "number": "old",
                            "amount": 50.0,
                            "vatAmount": 0,
                            "currency": "EUR",
                            "type": "INVOICE",
                            "failed": false,
                            "created": "2020-01-07T04:00:57.000+0000",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 11.9 EUR * 1.1 = 13.09
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.09")!))
        #expect(client.leakedSecrets([password]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "X-Domainrobot-Context") == "4")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "TollCat")
        #expect(request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Basic ") == true)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (InterNetXBillingProvider.searchURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (InterNetXBillingProvider.searchURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(
            providerID: .internetx,
            fields: [
                .clientID: username,
                .clientSecret: password,
            ]
        )
    }

    private func provider(_ client: any HTTPClient) -> InterNetXBillingProvider {
        InterNetXBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": Decimal(string: "1.1")!]))
        )
    }
}
