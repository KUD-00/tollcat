import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct PostHogBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "phx_MUST-NOT-LEAK"

    @Test("优先用折后金额，周期用对方的账单月")
    func prefersDiscountedAmount() async throws {
        let client = LiveProviderHarness.stub([
            (
                PostHogBillingProvider.billingURL(host: PostHogBillingProvider.usHost),
                LiveProviderHarness.body(LiveProviderHarness.fixture("posthog-billing"))
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "11.16")!))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        #expect(client.urls.allSatisfy { !$0.absoluteString.contains(secret) })
    }

    @Test("没有折后字段就用原价")
    func fallsBackToGrossAmount() async throws {
        let client = LiveProviderHarness.stub([
            (
                PostHogBillingProvider.billingURL(host: PostHogBillingProvider.usHost),
                LiveProviderHarness.json([
                    "current_total_amount_usd": "4.50",
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "4.50")!))
    }

    @Test("US 401 再试 EU")
    func retriesEUAfterUSUnauthorized() async throws {
        let client = LiveProviderHarness.stub([
            (
                PostHogBillingProvider.billingURL(host: PostHogBillingProvider.usHost),
                LiveProviderHarness.emptyJSON(status: 401)
            ),
            (
                PostHogBillingProvider.billingURL(host: PostHogBillingProvider.euHost),
                LiveProviderHarness.json([
                    "current_total_amount_usd": "2.00",
                    "billing_period": [
                        "current_period_start": "2026-08-01T00:00:00Z",
                        "current_period_end": "2026-09-01T00:00:00Z",
                    ],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: 2))
        #expect(client.urls.count >= 2)
        #expect(client.urls[0].host == PostHogBillingProvider.usHost)
        #expect(client.urls[1].host == PostHogBillingProvider.euHost)
    }

    @Test("金额解析优先折后")
    func amountPrefersDiscount() {
        let discounted = PostHogBillingProvider.Billing(
            current_total_amount_usd: FlexibleDecimal(Decimal(12)),
            current_total_amount_usd_after_discount: FlexibleDecimal(Decimal(string: "10.80")!),
            billing_period: nil
        )
        #expect(PostHogBillingProvider.amount(from: discounted) == Decimal(string: "10.80"))
        let gross = PostHogBillingProvider.Billing(
            current_total_amount_usd: FlexibleDecimal(Decimal(4)),
            current_total_amount_usd_after_discount: nil,
            billing_period: nil
        )
        #expect(PostHogBillingProvider.amount(from: gross) == 4)
    }

    private var credential: Credential {
        Credential(providerID: .posthog, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> PostHogBillingProvider {
        PostHogBillingProvider(httpClient: client, now: { now }, calendar: calendar)
    }
}
