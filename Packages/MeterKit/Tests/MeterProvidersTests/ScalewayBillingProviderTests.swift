import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ScalewayBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "scw-secret-MUST-NOT-LEAK"
    private let organizationID = "6170692e-7363-616c-6577-61792e636f6d"

    @Test("units+nanos 相加是本月消费")
    func readsConsumptions() async throws {
        let client = LiveProviderHarness.stub([
            (consumptionsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("scaleway-consumptions"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "15.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 X-Auth-Token，billing_period 是 YYYY-MM")
    func usesAuthTokenAndPeriod() async throws {
        let client = LiveProviderHarness.stub([
            (consumptionsURL, LiveProviderHarness.body(LiveProviderHarness.fixture("scaleway-consumptions"))),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "X-Auth-Token") == secret)
        #expect(consumptionsURL.query?.contains("billing_period=2026-08") == true)
        #expect(consumptionsURL.query?.contains("organization_id=\(organizationID)") == true)
    }

    @Test("nanos 单独也能还原分位")
    func nanosOnlyMoney() {
        let money = ScalewayBillingProvider.GoogleMoney(
            currency_code: "USD", units: nil, nanos: 250_000_000
        )
        #expect(money.decimal == Decimal(string: "0.25")!)
    }

    @Test("缺少 Organization ID")
    func missingOrganization() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .scaleway, fields: [.apiToken: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    @Test("非美元账户直接拒绝")
    func rejectsNonUSDWithoutRate() async {
        let client = LiveProviderHarness.stub([
            (
                consumptionsURL,
                LiveProviderHarness.json([
                    "consumptions": [
                        ["value": ["currency_code": "EUR", "units": "10", "nanos": 0]],
                    ],
                    "total_count": 1,
                ])
            ),
        ])
        await #expect(throws: ProviderError.unsupportedCurrency(providerID: .scaleway)) {
            _ = try await provider(client).fetch(credential: credential)
        }
    }

    private var consumptionsURL: URL {
        ScalewayBillingProvider.consumptionsURL(
            organizationID: organizationID,
            period: "2026-08",
            page: 1
        )
    }

    private var credential: Credential {
        Credential(providerID: .scaleway, fields: [.apiToken: secret, .accountID: organizationID])
    }

    private func provider(_ client: any HTTPClient) -> ScalewayBillingProvider {
        ScalewayBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates(.usdOnly)
        )
    }
}
