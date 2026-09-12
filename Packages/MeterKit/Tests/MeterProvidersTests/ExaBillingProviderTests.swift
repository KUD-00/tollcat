import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ExaBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let serviceKey = "EXA-SERVICE-KEY-MUST-NOT-LEAK"
    private let keyID = "550e8400-e29b-41d4-a716-446655440000"

    @Test("total_cost_usd 直接当合计")
    func readsTotalCost() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.body(LiveProviderHarness.fixture("exa-key-usage"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "8.25")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([serviceKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("service key 走 x-api-key 头")
    func usesXAPIKeyHeader() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL, LiveProviderHarness.json(["total_cost_usd": 1.0])),
        ])
        _ = try await provider(client).fetch(credential: credential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == serviceKey)
    }

    @Test("顶层金额缺失时用分项加总，不当成 0")
    func fallsBackToBreakdownSum() {
        let usage = ExaBillingProvider.Usage(
            api_key_id: nil,
            team_id: nil,
            total_cost_usd: nil,
            cost_breakdown: [
                ExaBillingProvider.BreakdownItem(
                    price_id: "a", price_name: "A", amount_usd: FlexibleDecimal(Decimal(string: "1.50")!)
                ),
                ExaBillingProvider.BreakdownItem(
                    price_id: "b", price_name: "B", amount_usd: FlexibleDecimal(Decimal(string: "2.25")!)
                ),
            ]
        )
        #expect(ExaBillingProvider.total(usage) == Decimal(string: "3.75"))
    }

    @Test("缺 key id 就报缺凭据，不去打一个残缺的 URL")
    func missingKeyIDFails() async {
        let client = LiveProviderHarness.stub([])
        let partial = Credential(providerID: .exa, fields: [.apiKey: serviceKey])
        await #expect(throws: ProviderError.missingCredential(providerID: .exa)) {
            _ = try await provider(client).fetch(credential: partial)
        }
    }

    private var usageURL: URL {
        ExaBillingProvider.usageURL(
            keyID: keyID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
    }

    private var credential: Credential {
        Credential(providerID: .exa, fields: [.apiKey: serviceKey, .keyID: keyID])
    }

    private func provider(_ client: any HTTPClient) -> ExaBillingProvider {
        ExaBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
