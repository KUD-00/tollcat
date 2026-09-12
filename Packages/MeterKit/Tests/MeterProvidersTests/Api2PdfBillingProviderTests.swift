import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct Api2PdfBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "api2pdf-key-MUST-NOT-LEAK"

    @Test("UserBalance 官方美元原样计入")
    func officialUSDIsExact() async throws {
        let client = LiveProviderHarness.stub([
            (
                Api2PdfBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("api2pdf-balance"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "12.76")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Authorization 原样 API Key，不加 Bearer")
    func usesRawAuthorizationHeader() async throws {
        let client = LiveProviderHarness.stub([
            (
                Api2PdfBillingProvider.balanceURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("api2pdf-balance"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == secret)
    }

    @Test("零余额是 $0，不是没读到")
    func zeroBalanceIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                Api2PdfBillingProvider.balanceURL,
                LiveProviderHarness.json(["UserBalance": 0] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == .zero)
    }

    @Test("缺 UserBalance 是畸形响应")
    func missingBalance() async {
        let client = LiveProviderHarness.stub([
            (
                Api2PdfBillingProvider.balanceURL,
                LiveProviderHarness.json([:] as [String: Any])
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
                    (Api2PdfBillingProvider.balanceURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .api2pdf, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> Api2PdfBillingProvider {
        Api2PdfBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
