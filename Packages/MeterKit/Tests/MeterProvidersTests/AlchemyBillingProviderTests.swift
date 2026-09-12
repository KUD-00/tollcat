import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct AlchemyBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "alchemy-access-MUST-NOT-LEAK"

    @Test("本月 monthToDate USD")
    func readsMonthToDateUSD() async throws {
        let url = AlchemyBillingProvider.summaryURL
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "data": [
                        "totals": [
                            "monthToDate": [
                                "amount": "1000",
                                "unit": "ALCHEMY_COMPUTE_UNIT",
                                "usd": "12.50",
                            ],
                            "last7Days": [
                                "amount": "100",
                                "unit": "ALCHEMY_COMPUTE_UNIT",
                                "usd": "1.00",
                            ],
                            "last30Days": [
                                "amount": "2000",
                                "unit": "ALCHEMY_COMPUTE_UNIT",
                                "usd": "20.00",
                            ],
                        ]
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.50")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(secret)")
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = AlchemyBillingProvider.summaryURL
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
        Credential(providerID: .alchemy, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> AlchemyBillingProvider {
        AlchemyBillingProvider(
            httpClient: client, now: { now }, calendar: calendar,
            rateSource: SharedExchangeRates()
        )
    }
}
