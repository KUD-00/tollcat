import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct MagaluCloudBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "magalu-key-MUST-NOT-LEAK"
    private let brlRate = Decimal(string: "0.2")!

    @Test("FOCUS BilledCost+BillingCurrency 按 ChargePeriodStart 归入本月")
    func sumsCurrentMonthUsage() async throws {
        let url = MagaluCloudBillingProvider.usageURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            offset: 0,
            calendar: calendar
        )
        let client = LiveProviderHarness.stub([
            (
                url,
                LiveProviderHarness.json([
                    "results": [
                        [
                            "SkuId": "sku-a",
                            "BillingCurrency": "BRL",
                            "BilledCost": "50.00",
                            "ChargePeriodStart": "2026-08-10T10:00:00+00:00",
                            "BillingPeriodStart": "2026-08-01T00:00:00+00:00",
                            "ProviderName": "Magalu Cloud",
                        ],
                        [
                            "SkuId": "sku-b",
                            "BillingCurrency": "BRL",
                            "BilledCost": "10.00",
                            "ChargePeriodStart": "2026-07-10T10:00:00+00:00",
                            "BillingPeriodStart": "2026-07-01T00:00:00+00:00",
                            "ProviderName": "Magalu Cloud",
                        ],
                    ]
                ] as [String: Any])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "10")!))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
        let request = try #require(client.requests.first)
        #expect(request.value(forHTTPHeaderField: "x-api-key") == secret)
    }

    @Test("空用量是本月 $0")
    func emptyUsageIsZero() async throws {
        let url = MagaluCloudBillingProvider.usageURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            offset: 0,
            calendar: calendar
        )
        let client = LiveProviderHarness.stub([
            (url, LiveProviderHarness.json(["results": [] as [Any]] as [String: Any])),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("401 / 403")
    func statusMapping() async {
        let url = MagaluCloudBillingProvider.usageURL(
            window: CalendarMonthWindow.current(now: now, calendar: calendar),
            offset: 0,
            calendar: calendar
        )
        await LiveProviderHarness.expectStatus(401, code: .unauthorized, key: .invalidCredentials) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
        await LiveProviderHarness.expectStatus(403, code: .forbidden, key: .insufficientPermissions) { status in
            try await provider(
                LiveProviderHarness.stub([(url, LiveProviderHarness.emptyJSON(status: status))])
            ).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .magalucloud, fields: [.apiKey: secret])
    }

    private func provider(_ client: any HTTPClient) -> MagaluCloudBillingProvider {
        MagaluCloudBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates(ExchangeRates(usdPerUnit: ["BRL": brlRate]))
        )
    }
}
