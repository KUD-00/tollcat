import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct ResendBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "re_MUST-NOT-LEAK"

    @Test("免费档按月额度头算比例")
    func freePlanUsesMonthlyQuotaHeader() async throws {
        let client = LiveProviderHarness.stub([
            (
                ResendBillingProvider.emailsURL,
                LiveProviderHarness.body(
                    LiveProviderHarness.fixture("resend-emails"),
                    headers: [
                        "x-resend-daily-quota": "12",
                        "x-resend-monthly-quota": "450",
                    ]
                )
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .freeTier)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.freeQuotaUsedRatio == 0.15)
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        #expect(client.requests.first?.value(forHTTPHeaderField: "User-Agent") == ResendBillingProvider.userAgent)
    }

    @Test("付费套餐没有金额字段就拒绝")
    func paidPlanHasNoAmount() async {
        let client = LiveProviderHarness.stub([
            (
                ResendBillingProvider.emailsURL,
                LiveProviderHarness.body(
                    LiveProviderHarness.fixture("resend-emails"),
                    headers: [
                        "x-resend-monthly-quota": "12000",
                    ]
                )
            ),
        ])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .billingAPIUnavailable)
    }

    @Test("额度头坏了就当 0")
    func malformedQuotaIsZero() {
        #expect(ResendBillingProvider.usedCount(from: nil) == nil)
        #expect(ResendBillingProvider.usedCount(from: "  ") == nil)
        #expect(ResendBillingProvider.usedCount(from: "-1") == nil)
        #expect(ResendBillingProvider.usedCount(from: "12") == 12)
        #expect(ResendBillingProvider.ratio(used: 450, included: 3_000) == 0.15)
        #expect(ResendBillingProvider.ratio(used: 9_000, included: 3_000) == 1)
    }

    private var credential: Credential {
        Credential(providerID: .resend, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> ResendBillingProvider {
        ResendBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
