import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct UpstashBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let email = "dev@example.com"
    private let secret = "upstash-MUST-NOT-LEAK"

    @Test("各库本月费用相加")
    func sumsMonthlyBilling() async throws {
        let client = LiveProviderHarness.stub([
            (UpstashBillingProvider.databasesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("upstash-databases"))),
            (UpstashBillingProvider.statsURL(id: "db-redis-1"), LiveProviderHarness.body(LiveProviderHarness.fixture("upstash-redis-stats"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 3.5))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(roundedUSD: 1.25))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("没有库是免费额度 $0")
    func emptyDatabasesAreFreeTier() async throws {
        let client = LiveProviderHarness.stub([
            (UpstashBillingProvider.databasesURL, LiveProviderHarness.body(Data("[]".utf8))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.freeQuotaUsedRatio == 0)
    }

    @Test("缺邮箱")
    func missingEmail() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .upstash, fields: [.apiKey: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var credential: Credential {
        Credential(providerID: .upstash, fields: [.email: email, .apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> UpstashBillingProvider {
        UpstashBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
