import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct BetterStackBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "betterstack-token-MUST-NOT-LEAK"

    @Test("attributes.cost 按产品相加是本月已花")
    func sumsProductCosts() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("betterstack-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: 13))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("betterstack-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("空 data 是 $0，不是没读到")
    func emptyDataIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.json(["data": [] as [Any]])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("401 / 403")
    func statusMapping() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([
                    (usageURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var usageURL: URL {
        BetterStackBillingProvider.usageURL(from: "2026-08-01", to: "2026-08-16")
    }

    private var credential: Credential {
        Credential(providerID: .betterstack, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> BetterStackBillingProvider {
        BetterStackBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
