import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct LinodeBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "linode-pat-MUST-NOT-LEAK"

    @Test("balance_uninvoiced 就是本月已花")
    func readsUninvoicedBalance() async throws {
        let client = LiveProviderHarness.stub([
            (LinodeBillingProvider.accountURL, LiveProviderHarness.body(LiveProviderHarness.fixture("linode-account"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "18.4")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (LinodeBillingProvider.accountURL, LiveProviderHarness.body(LiveProviderHarness.fixture("linode-account"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("缺未出账字段是畸形响应")
    func missingUninvoiced() async {
        let client = LiveProviderHarness.stub([
            (LinodeBillingProvider.accountURL, LiveProviderHarness.json(["balance": 0])),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var credential: Credential {
        Credential(providerID: .linode, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> LinodeBillingProvider {
        LinodeBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
