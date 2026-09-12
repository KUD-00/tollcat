import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct DeepgramBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "deepgram-key-MUST-NOT-LEAK"
    private let projectID = "proj_9f8b7c6d5e4a3b2c1d0e"

    @Test("breakdown dollars 合计为本月用量")
    func sumsBreakdownDollars() async throws {
        let client = pinnedStub()
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "125.5")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("认证走 Token 前缀")
    func usesTokenScheme() async throws {
        let client = pinnedStub()
        _ = try await provider(client).fetch(credential: pinnedCredential)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Token \(secret)")
    }

    @Test("没填项目就自己查一次 /projects")
    func discoversProjectWhenUnpinned() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (
                DeepgramBillingProvider.projectsURL,
                LiveProviderHarness.body(LiveProviderHarness.fixture("deepgram-projects"))
            ),
            (
                DeepgramBillingProvider.breakdownURL(projectID: projectID, window: window),
                LiveProviderHarness.body(LiveProviderHarness.fixture("deepgram-breakdown"))
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: Credential(providerID: .deepgram, fields: [.apiKey: secret])
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "125.5")!))
        #expect(client.urls.first == DeepgramBillingProvider.projectsURL)
    }

    @Test("没有结果是 $0")
    func emptyBreakdownIsZero() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (
                DeepgramBillingProvider.breakdownURL(projectID: projectID, window: window),
                LiveProviderHarness.json(["results": [] as [Any]])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: pinnedCredential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    private var pinnedCredential: Credential {
        Credential(providerID: .deepgram, fields: [.apiKey: secret, .projectID: projectID])
    }

    private func pinnedStub() -> RecordingHTTPClient {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        return LiveProviderHarness.stub([
            (
                DeepgramBillingProvider.breakdownURL(projectID: projectID, window: window),
                LiveProviderHarness.body(LiveProviderHarness.fixture("deepgram-breakdown"))
            ),
        ])
    }

    private func provider(_ client: any HTTPClient) -> DeepgramBillingProvider {
        DeepgramBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
