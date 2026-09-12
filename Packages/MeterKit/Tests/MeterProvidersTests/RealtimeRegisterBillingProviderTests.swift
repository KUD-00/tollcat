import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct RealtimeRegisterBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "rtr-key-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("本月 EUR 流水合计（分）")
    func sumsCurrentMonthTransactions() async throws {
        let url = RealtimeRegisterBillingProvider.transactionsURL(offset: 0)
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "entities": [
                        [
                            "date": "2026-08-05T12:00:00Z",
                            "amount": 1200,
                            "currency": "EUR",
                            "processType": "domain",
                            "processAction": "RENEW",
                            "processIdentifier": "example.com",
                        ],
                        [
                            "date": "2026-07-01T12:00:00Z",
                            "amount": 99900,
                            "currency": "EUR",
                            "processType": "domain",
                            "processAction": "CREATE",
                            "processIdentifier": "old.com",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 12.00 EUR * 1.10 = 13.20 USD
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "13.2")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "ApiKey \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = RealtimeRegisterBillingProvider.transactionsURL(offset: 0)
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials, url: url)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions, url: url)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        url: URL
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .realtimeregister, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> RealtimeRegisterBillingProvider {
        RealtimeRegisterBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
