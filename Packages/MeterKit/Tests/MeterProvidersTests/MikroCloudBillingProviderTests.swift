import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MikroCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "mikrocloud-token-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("发票 total+currency 按 created_at 归入本月")
    func sumsCurrentMonthInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (
                MikroCloudBillingProvider.invoicesURL,
                LiveProviderHarness.json([
                    [
                        "id": "in_1",
                        "number": "SINV-0079",
                        "total": 12.5,
                        "currency": "EUR",
                        "created_at": "2026-08-16 01:47:28",
                        "status": "paid",
                    ],
                    [
                        "id": "in_2",
                        "number": "SINV-0070",
                        "total": 100.0,
                        "currency": "EUR",
                        "created_at": "2026-07-01 00:00:00",
                        "status": "paid",
                    ],
                ] as [Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.75")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("空发票列表是本月 $0")
    func emptyInvoicesAreZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                MikroCloudBillingProvider.invoicesURL,
                LiveProviderHarness.json([] as [Any])
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
                    (MikroCloudBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (MikroCloudBillingProvider.invoicesURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .mikrocloud, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MikroCloudBillingProvider {
        MikroCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
