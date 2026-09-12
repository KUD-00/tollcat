import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct SeewebBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "seeweb-token-MUST-NOT-LEAK"
    private let euroRate = Decimal(string: "1.10")!

    @Test("本月 servers+templates+snapshots EUR 合计")
    func sumsMonthCosts() async throws {
        let servers = SeewebBillingProvider.billingURL(kind: "servers", year: 2026, month: 8)
        let templates = SeewebBillingProvider.billingURL(kind: "templates", year: 2026, month: 8)
        let snapshots = SeewebBillingProvider.billingURL(kind: "snapshots", year: 2026, month: 8)
        let client = LiveProviderHarness.stub([
            (
                servers,
                LiveProviderHarness.json([
                    ["name": "ec200200", "plan": "ECS1", "cost": 2.64],
                ] as [[String: Any]])
            ),
            (
                templates,
                LiveProviderHarness.json([
                    ["name": "ei200112", "cost": 0.18],
                ] as [[String: Any]])
            ),
            (
                snapshots,
                LiveProviderHarness.json([
                    "year": 2026,
                    "month": 8,
                    "total_cost": 3.7,
                    "snapshots": [],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        // 6.52 EUR × 1.10，折算按分四舍五入到 7.17。
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "7.17")!))
        #expect(snapshot.converted?.currency == "EUR")
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-APITOKEN") == secret)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = SeewebBillingProvider.billingURL(kind: "servers", year: 2026, month: 8)
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
        Credential(providerID: .seeweb, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> SeewebBillingProvider {
        SeewebBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["EUR": euroRate]))
        )
    }
}
