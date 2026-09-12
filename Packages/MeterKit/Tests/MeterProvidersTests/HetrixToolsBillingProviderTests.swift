import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct HetrixToolsBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "hetrix-token-MUST-NOT-LEAK"

    @Test("account_credit.balance 官方美元原样计入")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                HetrixToolsBillingProvider.limitsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("hetrixtools-limits"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "12.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (
                HetrixToolsBillingProvider.limitsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("hetrixtools-limits"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer " + secret)
    }

    @Test("零余额是 $0，不是没读到")
    func zeroBalanceIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                HetrixToolsBillingProvider.limitsURL,
                LiveProviderHarness.json([
                    "account_credit": ["balance": 0] as [String: Any],
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == .zero)
    }

    @Test("缺 account_credit.balance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (
                HetrixToolsBillingProvider.limitsURL,
                LiveProviderHarness.json(["uptime": ["monitors": ["usage": 1]] as [String: Any]] as [String: Any])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .malformedResponse)
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
                    (HetrixToolsBillingProvider.limitsURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .hetrixtools, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> HetrixToolsBillingProvider {
        HetrixToolsBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
