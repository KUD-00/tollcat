import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct LeasewebBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "leaseweb-key-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("发票 total+currency 按 date 归入本月")
    func sumsCurrentMonthInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                LeasewebBillingProvider.invoicesURL(offset: 0),
                LiveProviderHarness.json([
                    "invoices": [
                        [
                            "id": "00000001",
                            "currency": "EUR",
                            "date": "2026-08-06T00:00:00+00:00",
                            "dueDate": "2026-08-30T00:00:00+00:00",
                            "openAmount": 10.0,
                            "status": "PAID",
                            "total": 12.5,
                        ],
                        [
                            "id": "00000002",
                            "currency": "EUR",
                            "date": "2026-07-01T00:00:00+00:00",
                            "total": 100.0,
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.75")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-LSW-Auth") == secret)
    }

    @Test("空发票列表是本月 $0")
    func emptyInvoicesAreZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                LeasewebBillingProvider.invoicesURL(offset: 0),
                LiveProviderHarness.json(["invoices": [] as [Any]] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (LeasewebBillingProvider.invoicesURL(offset: 0), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (LeasewebBillingProvider.invoicesURL(offset: 0), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .leaseweb, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> LeasewebBillingProvider {
        LeasewebBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
