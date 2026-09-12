import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MistralBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "mistral-admin-MUST-NOT-LEAK"

    @Test("按品类 cost 相加")
    func sumsCategoryCosts() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("mistral-admin-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "16")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 x-api-key，不是 Bearer")
    func usesXAPIKeyHeader() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("mistral-admin-usage"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == secret)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(usageURL.query?.contains("year=2026") == true)
        #expect(usageURL.query?.contains("month=8") == true)
    }

    @Test("顶层 total_cost 优先于品类相加")
    func prefersExplicitTotal() async throws {
        let client = LiveProviderHarness.stub([
            (
                usageURL,
                LiveProviderHarness.json([
                    "currency": "USD",
                    "total_cost": 3.5,
                    "chat": ["cost": 100],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "3.5")!))
    }

    @Test("401 / 403")
    func statusMapping() async {
        for (status, code, key) in [
            (401, ProviderError.Code.unauthorized, RemediationKey.invalidCredentials),
            (403, ProviderError.Code.forbidden, RemediationKey.insufficientPermissions),
        ] {
            let client = LiveProviderHarness.stub([
                (usageURL, LiveProviderHarness.emptyJSON(status: status)),
            ])
            let error = await #expect(throws: ProviderError.self) {
                try await provider(client).fetch(credential: credential)
            }
            #expect(error?.code == code)
            #expect(error?.remediationKey == key)
        }
    }

    @Test("缺少 Admin API key")
    func missingKey() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .mistral, fields: [:])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var usageURL: URL {
        MistralBillingProvider.usageURL(year: 2026, month: 8)
    }

    private var credential: Credential {
        Credential(providerID: .mistral, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MistralBillingProvider {
        MistralBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
