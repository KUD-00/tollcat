import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct Click2MailBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let user = "c2m-user"
    private let pass = "c2m-pass-MUST-NOT-LEAK"

    @Test("本月 job cost 相加")
    func sumsCurrentMonthJobCosts() async throws {
        let client = LiveProviderHarness.stub([
            (
                Click2MailBillingProvider.jobsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("click2mail-jobs"))
            ),
            (
                Click2MailBillingProvider.costURL(jobID: 101),
                LiveProviderHarness.body(LiveProviderHarness.fixture("click2mail-job-cost"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "4.2")!))
        #expect(client.leakedSecrets([user, pass]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 HTTP Basic")
    func usesBasic() async throws {
        let client = LiveProviderHarness.stub([
            (
                Click2MailBillingProvider.jobsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("click2mail-jobs"))
            ),
            (
                Click2MailBillingProvider.costURL(jobID: 101),
                LiveProviderHarness.body(LiveProviderHarness.fixture("click2mail-job-cost"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == Click2MailBillingProvider.basicAuthorization(username: user, password: pass)
        )
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
                    (Click2MailBillingProvider.jobsURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .click2mail, fields: [.clientID: user, .clientSecret: pass])
    }

    private func provider(_ client: any HTTPClient) -> Click2MailBillingProvider {
        Click2MailBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
