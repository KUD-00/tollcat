import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DeepInfraBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "deepinfra-key-MUST-NOT-LEAK"

    @Test("total_cost 按美分折成本月花费")
    func readsMonthlyUsageInCents() async throws {
        let client = LiveProviderHarness.stub([
            (DeepInfraBillingProvider.usageURL(period: "2026.08"), LiveProviderHarness.body(LiveProviderHarness.fixture("deepinfra-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer，from 是 YYYY.MM")
    func usesBearerAndPeriodQuery() async throws {
        let client = LiveProviderHarness.stub([
            (DeepInfraBillingProvider.usageURL(period: "2026.08"), LiveProviderHarness.body(LiveProviderHarness.fixture("deepinfra-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.url?.query?.contains("from=2026.08") == true)
    }

    @Test("缺 months 是畸形响应")
    func missingMonths() async {
        let client = LiveProviderHarness.stub([
            (DeepInfraBillingProvider.usageURL(period: "2026.08"), LiveProviderHarness.json(["initial_month": "2026.01"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .deepinfra, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> DeepInfraBillingProvider {
        DeepInfraBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
