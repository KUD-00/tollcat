import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TypesenseBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "typesense-mgmt-key-MUST-NOT-LEAK"

    @Test("本月发票 amount_cents 合计是花费，上个月那张不算")
    func sumsCurrentMonthInvoices() async throws {
        let client = LiveProviderHarness.stub([
            (TypesenseBillingProvider.invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("typesense-invoices"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "5.7")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走管理 API key 头，不进 query")
    func usesManagementKeyHeader() async throws {
        let client = LiveProviderHarness.stub([
            (TypesenseBillingProvider.invoicesURL, LiveProviderHarness.body(LiveProviderHarness.fixture("typesense-invoices"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-TYPESENSE-CLOUD-MANAGEMENT-API-KEY") == secret)
        #expect(request.url?.query?.contains(secret) != true)
    }

    @Test("本月还没出发票时报没读到，不是 $0")
    func missingCurrentMonthIsUnread() async throws {
        let client = LiveProviderHarness.stub([
            (TypesenseBillingProvider.invoicesURL, LiveProviderHarness.json(["invoices": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == nil)
        #expect(snapshot.kind == .usage)
    }

    private var credential: Credential {
        Credential(providerID: .typesense, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> TypesenseBillingProvider {
        TypesenseBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
