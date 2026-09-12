import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ShipStationBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "shipstation-key-MUST-NOT-LEAK"

    @Test("carriers.balance 相加是预充值余额")
    func sumsCarrierBalances() async throws {
        let client = LiveProviderHarness.stub([
            (
                ShipStationBillingProvider.carriersURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("shipstation-carriers"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .prepaid)
        #expect(snapshot.balanceUSD == Money(usd: Decimal(string: "19.75")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 API-Key 头")
    func usesAPIKeyHeader() async throws {
        let client = LiveProviderHarness.stub([
            (
                ShipStationBillingProvider.carriersURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("shipstation-carriers"))
            ),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "API-Key") == secret)
    }

    @Test("空 carriers 是 $0")
    func emptyIsZero() async throws {
        let client = LiveProviderHarness.stub([
            (
                ShipStationBillingProvider.carriersURL,
                LiveProviderHarness.json(["carriers": [] as [Any]])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.balanceUSD == .zero)
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
                    (ShipStationBillingProvider.carriersURL, LiveProviderHarness.emptyJSON(status: status)),
                ])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .shipstation, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ShipStationBillingProvider {
        ShipStationBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
