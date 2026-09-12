import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MixpeekBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "mxp_sk_MUST-NOT-LEAK"

    @Test("当期 current_spending_usd")
    func readsCurrentSpendingUSD() async throws {
        let url = MixpeekBillingProvider.spendingCapsURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "current_spending_cents": 23450,
                    "current_spending_usd": 234.5,
                    "hard_cap_enabled": false,
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "234.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = MixpeekBillingProvider.spendingCapsURL
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials, url: url)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions, url: url)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey,
        url: URL
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .mixpeek, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> MixpeekBillingProvider {
        MixpeekBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
