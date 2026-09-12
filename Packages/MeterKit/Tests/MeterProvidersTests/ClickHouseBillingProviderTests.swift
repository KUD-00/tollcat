import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ClickHouseBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let keyID = "ch-key-id"
    private let secret = "ch-key-secret-MUST-NOT-LEAK"
    private let organizationID = "015d5fc2-490f-4dcd-958d-567b556e008e"

    @Test("grandTotalCHC 按 1 CHC = $1，日线走 metrics")
    func readsUsageCost() async throws {
        let client = fullStub()
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "8.5")!))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 6))
        #expect(daily[LiveProviderHarness.date(2026, 8, 15)] == Money(usd: Decimal(string: "2.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Basic，secret 不进 URL")
    func usesBasicAuth() async throws {
        let client = fullStub()
        _ = try await provider(client).fetch(credential: pinnedCredential)
        let request = try #require(client.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == ClickHouseBillingProvider.basicAuthorization(id: keyID, secret: secret)
        )
        #expect(client.leakedSecrets([secret]).isEmpty)
    }

    @Test("没填组织就自己查一次 /organizations")
    func discoversOrganizationWhenUnpinned() async throws {
        let client = LiveProviderHarness.stub([
            (
                ClickHouseBillingProvider.organizationsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("clickhouse-organizations"))
            ),
            (
                usageCostURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("clickhouse-usage-cost"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .clickhouse, fields: [.clientID: keyID, .clientSecret: secret])
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "8.5")!))
        #expect(client.urls.first == ClickHouseBillingProvider.organizationsURL)
    }

    @Test("缺少 Key Secret")
    func missingSecret() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .clickhouse, fields: [.clientID: keyID])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var usageCostURL: URL {
        ClickHouseBillingProvider.usageCostURL(
            organizationID: organizationID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var pinnedCredential: Credential {
        Credential(
            providerID: .clickhouse,
            fields: [.clientID: keyID, .clientSecret: secret, .accountID: organizationID]
        )
    }

    private func fullStub() -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (usageCostURL, LiveProviderHarness.body(LiveProviderHarness.fixture("clickhouse-usage-cost"))),
        ])
    }

    private func provider(_ client: any HTTPClient) -> ClickHouseBillingProvider {
        ClickHouseBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
