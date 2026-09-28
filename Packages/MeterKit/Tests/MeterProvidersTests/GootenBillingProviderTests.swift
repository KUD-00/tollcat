import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct GootenBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let recipe = "gooten-recipe-MUST-NOT-LEAK"
    private let billingKey = "gooten-billing-MUST-NOT-LEAK"

    @Test("本月 orderbilling Total.Price 合计")
    func sumsBillingTotals() async throws {
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let search = GootenBillingProvider.ordersSearchURL(
            recipeID: recipe,
            billingKey: billingKey,
            window: window,
            calendar: calendar
        )
        let bill1 = GootenBillingProvider.billingURL(
            orderID: "ord-1",
            recipeID: recipe,
            billingKey: billingKey
        )
        let bill2 = GootenBillingProvider.billingURL(
            orderID: "ord-2",
            recipeID: recipe,
            billingKey: billingKey
        )
        let client = LiveProviderHarness.stub([
            (search, LiveProviderHarness.body(LiveProviderHarness.fixture("gooten-orders"))),
            (bill1, LiveProviderHarness.body(LiveProviderHarness.fixture("gooten-billing-1"))),
            (bill2, LiveProviderHarness.body(LiveProviderHarness.fixture("gooten-billing-2"))),
        ])
        let snapshot = try await GootenBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar,
            rateSource: SharedExchangeRates()
        ).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "50.00")!))
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("查询日期按账期日历写，东边时区的 1 号不会退成上月最后一天")
    func searchDatesFollowCalendarTimeZone() throws {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let window = CalendarMonthWindow.current(now: now, calendar: tokyo)
        let url = GootenBillingProvider.ordersSearchURL(
            recipeID: recipe,
            billingKey: billingKey,
            window: window,
            calendar: tokyo
        )
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let from = items.first { $0.name == "fromDate" }?.value
        let to = items.first { $0.name == "toDate" }?.value
        #expect(from?.hasSuffix("-01") == true)
        #expect(to?.hasSuffix("-01") == true)
    }

    private var credential: Credential {
        Credential(providerID: .gooten, fields: [.clientID: recipe, .clientSecret: billingKey])
    }
}
