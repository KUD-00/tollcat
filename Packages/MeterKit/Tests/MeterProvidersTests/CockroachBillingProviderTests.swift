import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CockroachBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "cockroach-secret-MUST-NOT-LEAK"

    @Test("草稿发票 totals 是本月花费，已出账那张不算")
    func readsDraftInvoice() async throws {
        let client = LiveProviderHarness.stub([
            (CockroachBillingProvider.invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("cockroach-invoices"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer 和 Cc-Version")
    func usesBearerAndVersion() async throws {
        let client = LiveProviderHarness.stub([
            (CockroachBillingProvider.invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("cockroach-invoices"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
        #expect(request.value(forHTTPHeaderField: "Cc-Version") == CockroachBillingProvider.apiVersion)
    }

    @Test("还没生成草稿时报没读到，不是 $0")
    func missingDraftIsUnread() async throws {
        let client = LiveProviderHarness.stub([
            (CockroachBillingProvider.invoicesURL, LiveProviderHarness.json(["invoices": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(snapshot.kind == .usage)
    }

    private var credential: Credential {
        Credential(providerID: .cockroach, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> CockroachBillingProvider {
        CockroachBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(.usdOnly)
        )
    }
}
