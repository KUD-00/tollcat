import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DatadogBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let apiKey = "dd-api-MUST-NOT-LEAK"
    private let appKey = "dd-app-MUST-NOT-LEAK"

    @Test("summary 的 total_cost 是本月估算")
    func readsTotalCost() async throws {
        let client = LiveProviderHarness.stub([
            (costURL(host: "api.datadoghq.com"), LiveProviderHarness.body(LiveProviderHarness.fixture("datadog-estimated-cost"))),
        ])
        let snapshot = try await provider(client).fetch(credential: usCredential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "42.5")!))
        #expect(client.leakedSecrets([apiKey, appKey]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 DD-API-KEY 和 DD-APPLICATION-KEY")
    func usesDatadogHeaders() async throws {
        let client = LiveProviderHarness.stub([
            (costURL(host: "api.datadoghq.com"), LiveProviderHarness.body(LiveProviderHarness.fixture("datadog-estimated-cost"))),
        ])
        _ = try await provider(client).fetch(credential: usCredential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "DD-API-KEY") == apiKey)
        #expect(request.value(forHTTPHeaderField: "DD-APPLICATION-KEY") == appKey)
        #expect(request.url?.query?.contains("view=summary") == true)
        #expect(request.url?.query?.contains("start_month=2026-08-01") == true)
    }

    @Test("eu 站点打到 api.datadoghq.eu")
    func mapsEUSite() async throws {
        let url = costURL(host: "api.datadoghq.eu")
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("datadog-estimated-cost"))),
        ])
        _ = try await provider(client).fetch(
            credential: Credential(
                providerID: .datadog,
                fields: [.apiKey: apiKey, .apiToken: appKey, .accountID: "eu"]
            )
        )
        #expect(client.urls.first?.host == "api.datadoghq.eu")
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("不认识的站点直接拒绝，不把 key 打出去")
    func rejectsUnknownSite() async {
        let client = LiveProviderHarness.stub([])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(
                credential: Credential(
                    providerID: .datadog,
                    fields: [.apiKey: apiKey, .apiToken: appKey, .accountID: "evil.example"]
                )
            )
        }
        // 钥匙是在的，坏的是站点名——不是 missingCredential，别把用户支回向导重填 key。
        #expect(error?.code == .malformedResponse)
        #expect(client.requests.isEmpty)
    }

    @Test("有行但没有 total_cost 是畸形响应")
    func missingTotalCost() async {
        let client = LiveProviderHarness.stub([
            (
                costURL(host: "api.datadoghq.com"),
                LiveProviderHarness.json(["data": [["id": "org1", "attributes": ["org_name": "x"]]]])
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: usCredential)
        }
        #expect(error?.code == .malformedResponse)
    }

    private var usCredential: Credential {
        Credential(providerID: .datadog, fields: [.apiKey: apiKey, .apiToken: appKey, .accountID: "us1"])
    }

    private func costURL(host: String) -> URL {
        DatadogBillingProvider.estimatedCostURL(
            host: host,
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private func provider(_ client: any HTTPClient) -> DatadogBillingProvider {
        DatadogBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
