import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FireworksBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "fw-api-MUST-NOT-LEAK"
    private let accountID = "acct-demo"

    @Test("lineItems 的 units+nanos 是美元，日线走 usageBuckets")
    func readsSummaryMoney() async throws {
        let client = LiveProviderHarness.stub([
            (summaryURL, LiveProviderHarness.body(LiveProviderHarness.fixture("fireworks-billing-summary"))),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.5")!))
        let daily = try #require(snapshot.dailyUSD)
        #expect(daily[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: 4))
        #expect(daily[LiveProviderHarness.date(2026, 8, 7)] == Money(usd: Decimal(string: "5.5")!))
        #expect(daily[LiveProviderHarness.date(2026, 8, 15)] == Money(usd: 3))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("nanos 单独也能还原分位")
    func nanosOnlyMoney() {
        let money = FireworksBillingProvider.GoogleMoney(
            currencyCode: "USD", units: nil, nanos: 250_000_000
        )
        #expect(money.decimal == Decimal(string: "0.25")!)
    }

    @Test("缺 lineItems 时退回逐日相加")
    func bucketsFallBackWhenLineItemsMissing() async throws {
        let client = LiveProviderHarness.stub([
            (
                summaryURL,
                LiveProviderHarness.json([
                    "usageBuckets": [
                        [
                            "startTime": "2026-08-03T00:00:00Z",
                            "lineItems": [
                                ["totalCost": ["currencyCode": "USD", "units": "2", "nanos": 0]],
                            ],
                        ],
                        [
                            "startTime": "2026-08-04T00:00:00Z",
                            "lineItems": [
                                ["totalCost": ["currencyCode": "USD", "units": "3", "nanos": 0]],
                            ],
                        ],
                    ],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: 5))
    }

    @Test("请求按天切、endTime 是下月 1 号")
    func requestsDailyWindow() {
        let query = summaryURL.query ?? ""
        #expect(query.contains("granularity=DAILY"))
        #expect(query.contains("startTime="))
        #expect(query.contains("endTime="))
    }

    @Test("缺少 Account ID")
    func missingAccount() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .fireworks, fields: [.apiKey: secret])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    private var summaryURL: URL {
        FireworksBillingProvider.summaryURL(
            accountID: accountID,
            window: CalendarMonthWindow.current(now: now, calendar: calendar)
        )
    }

    private var credential: Credential {
        Credential(providerID: .fireworks, fields: [.apiKey: secret, .accountID: accountID])
    }

    private func provider(_ client: any HTTPClient) -> FireworksBillingProvider {
        FireworksBillingProvider(
            httpClient: client, now: { now }, calendar: calendar, rateSource: SharedExchangeRates()
        )
    }
}
