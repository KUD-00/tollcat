import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct IBMCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let accountID = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"
    private let apiKey = "ibm-apikey-MUST-NOT-LEAK"

    @Test("resources billable_cost 相加是本月花费")
    func sumsBillableCost() async throws {
        let client = fullStub()
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.5")!))
        #expect(client.leakedSecrets([apiKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("先换 IAM token，apikey 只在表单体里")
    func exchangesIAMToken() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.requests.count == 2)
        let token = try #require(client.requests.first)
        #expect(token.url == IBMCloudBillingProvider.tokenURL)
        let body = String(data: token.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey"))
        #expect(body.contains("apikey=\(apiKey)"))
        #expect(token.url?.absoluteString.contains(apiKey) == false)
        let usage = try #require(client.requests.last)
        #expect(usage.value(forHTTPHeaderField: "Authorization") == "Bearer ibm-access-MUST-NOT-LEAK")
        #expect(usage.url?.path.hasSuffix("/v4/accounts/\(accountID)/usage/2026-08") == true)
    }

    @Test("没有 billable_cost 的资源当 0，空表是 $0")
    func emptyResourcesIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (IBMCloudBillingProvider.tokenURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ibm-iam-token"))),
            (
                usageURL,
                LiveProviderHarness.json([
                    "account_id": accountID,
                    "currency_code": "USD",
                    "month": "2026-08",
                    "resources": [] as [Any],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money.zero)
    }

    private var usageURL: URL {
        IBMCloudBillingProvider.usageURL(
            accountID: accountID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var credential: Credential {
        Credential(providerID: .ibm, fields: [.accountID: accountID, .apiKey: apiKey])
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (IBMCloudBillingProvider.tokenURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ibm-iam-token"))),
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("ibm-account-usage"))),
        ])
    }

    private func provider(_ client: any HTTPClient) -> IBMCloudBillingProvider {
        IBMCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(.usdOnly)
        )
    }
}
