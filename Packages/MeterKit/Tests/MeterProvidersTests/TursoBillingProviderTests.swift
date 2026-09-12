import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TursoBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "turso-token-MUST-NOT-LEAK"
    private let org = "acme"

    @Test("upcoming 发票的 amount_due 是美元字符串")
    func readsUpcomingInvoice() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("turso-invoices"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10.29")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("请求 type=upcoming")
    func requestsUpcomingOnly() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("turso-invoices"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        #expect(invoicesURL.query?.contains("type=upcoming") == true)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("没有 upcoming 时报没读到，不是 $0")
    func noUpcomingIsNotZero() async throws {
        let client = LiveProviderHarness.stub([
            (invoicesURL, LiveProviderHarness.json(["invoices": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(!snapshot.hasBillableMetrics)
    }

    @Test("缺少组织 slug")
    func missingOrg() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .turso, fields: [.apiToken: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var invoicesURL: URL {
        TursoBillingProvider.invoicesURL(organization: org)
    }

    private var credential: Credential {
        Credential(providerID: .turso, fields: [.apiToken: secret, .accountID: org])
    }

    private func provider(_ client: any HTTPClient) -> TursoBillingProvider {
        TursoBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
