import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct QiniuBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let ak = "qiniu-ak"
    private let sk = "qiniu-sk-MUST-NOT-LEAK"

    @Test("bill overview fee ÷1e8 按币种折")
    func billOverview() async throws {
        let url = QiniuBillingProvider.billOverviewURL(month: now, calendar: calendar)
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.body(LiveProviderHarness.fixture("qiniu-bill-overview"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD != nil)
        #expect(client.leakedSecrets([ak, sk]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    private var credential: Credential {
        Credential(providerID: .qiniu, fields: [.accessKeyID: ak, .secretAccessKey: sk])
    }

    private func provider(_ client: any HTTPClient) -> QiniuBillingProvider {
        QiniuBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: LiveProviderHarness.catalogRates
        )
    }
}
