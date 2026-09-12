import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct HuggingFaceBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "hf_MUST-NOT-LEAK"
    private let org = "acme-org"

    @Test("个人 usage-v2 把 microUSD 加成美元")
    func sumsPersonalMicroUSD() async throws {
        let client = LiveProviderHarness.stub([
            (personalURL, LiveProviderHarness.body(LiveProviderHarness.fixture("huggingface-usage-v2"))),
        ])
        let snapshot = try await provider(client).fetch(credential: personalCredential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: 10))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("填了组织名走 organizations 那条")
    func usesOrgEndpointWhenPinned() async throws {
        let client = LiveProviderHarness.stub([
            (orgURL, LiveProviderHarness.body(LiveProviderHarness.fixture("huggingface-usage-v2"))),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .huggingface, fields: [.apiToken: secret, .accountID: org])
        )
        #expect(snapshot.currentSpendUSD == Money(usd: 10))
        #expect(client.urls.first == orgURL)
        #expect(!client.urls.contains(personalURL))
    }

    @Test("日期是本月 1 号和下月 1 号的毫秒")
    func monthBoundsAreMilliseconds() {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let start = HuggingFaceBillingProvider.milliseconds(window.start)
        let end = HuggingFaceBillingProvider.milliseconds(window.nextStart)
        let query = personalURL.query ?? ""
        #expect(query.contains("startDate=\(start)"))
        #expect(query.contains("endDate=\(end)"))
        #expect(start == 1_785_542_400_000)
        #expect(end == 1_788_220_800_000)
    }

    @Test("microUSD 要除以 1e6")
    func microUSDScale() {
        #expect(HuggingFaceBillingProvider.money(microUSD: 1_500_000) == Decimal(string: "1.5")!)
    }

    @Test("401")
    func unauthorized() async {
        let client = LiveProviderHarness.stub([
            (personalURL, LiveProviderHarness.emptyJSON(status: 401)),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: personalCredential)
        }
        #expect(error?.code == .unauthorized)
    }

    private var personalURL: URL {
        HuggingFaceBillingProvider.usageURL(
            organization: nil,
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
    }

    private var orgURL: URL {
        HuggingFaceBillingProvider.usageURL(
            organization: org,
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
    }

    private var personalCredential: Credential {
        Credential(providerID: .huggingface, fields: [.apiToken: secret])
    }

    private func provider(_ client: any HTTPClient) -> HuggingFaceBillingProvider {
        HuggingFaceBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
