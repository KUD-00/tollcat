import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ThanksIOBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "thanksio-token-MUST-NOT-LEAK"

    @Test("本月 grand_total 美分合计")
    func sumsCurrentMonthCents() async throws {
        let client = LiveProviderHarness.stub([
            (
                ThanksIOBillingProvider.ordersURL(page: 1),
                LiveProviderHarness.body(LiveProviderHarness.fixture("thanksio-orders"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "2.00")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Bearer")
    func usesBearer() async throws {
        let client = LiveProviderHarness.stub([
            (
                ThanksIOBillingProvider.ordersURL(page: 1),
                LiveProviderHarness.body(LiveProviderHarness.fixture("thanksio-orders"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer " + secret)
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
                    (ThanksIOBillingProvider.ordersURL(page: 1), LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .thanksio, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> ThanksIOBillingProvider {
        ThanksIOBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
