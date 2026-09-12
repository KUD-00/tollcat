import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DigitalOceanBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "dop_v1_MUST-NOT-LEAK"

    @Test("month_to_date_usage 就是本月已花")
    func monthToDateUsage() async throws {
        let client = LiveProviderHarness.stub([
            (DigitalOceanBillingProvider.balanceURL, LiveProviderHarness.body(LiveProviderHarness.fixture("digitalocean-balance"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 11.21))
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("用量为 0 仍是用量读数，不把结余当预充值")
    func zeroUsageIsUsageNotPrepaid() async throws {
        let client = LiveProviderHarness.stub([
            (
                DigitalOceanBillingProvider.balanceURL,
                LiveProviderHarness.json([
                    "account_balance": "0.00",
                    "generated_at": "2026-09-12T00:00:00Z",
                    "month_to_date_balance": "0.00",
                    "month_to_date_usage": "0.00",
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.balanceUSD == nil)
    }

    @Test("缺用量字段是畸形响应")
    func missingUsage() async {
        let client = LiveProviderHarness.stub([
            (DigitalOceanBillingProvider.balanceURL, LiveProviderHarness.json(["account_balance": "1"])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .digitalocean, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> DigitalOceanBillingProvider {
        DigitalOceanBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
