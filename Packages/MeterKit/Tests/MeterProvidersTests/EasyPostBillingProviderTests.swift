import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct EasyPostBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "easypost-key-MUST-NOT-LEAK"

    @Test("balance 官方美元原样计入")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                EasyPostBillingProvider.usersURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("easypost-user"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 HTTP Basic，密码为空")
    func usesBasicWithEmptyPassword() async throws {
        let client = LiveProviderHarness.stub([
            (
                EasyPostBillingProvider.usersURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("easypost-user"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == EasyPostBillingProvider.basicAuthorization(apiKey: secret)
        )
    }

    @Test("零余额是 $0，不是没读到")
    func zeroBalanceIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                EasyPostBillingProvider.usersURL,
                LiveProviderHarness.json([
                    "id": "user_zero",
                    "balance": "0.00000",
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == .zero)
    }

    @Test("缺 balance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (
                EasyPostBillingProvider.usersURL,
                LiveProviderHarness.json(["id": "user_x"] as [String: Any])
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
                    (EasyPostBillingProvider.usersURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .easypost, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> EasyPostBillingProvider {
        EasyPostBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
