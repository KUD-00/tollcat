import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct TwilioBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let sid = "ACaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa12"
    private let keySID = "SKbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb34"
    private let secret = "twilio-secret-MUST-NOT-LEAK"

    @Test("Daily totalprice 按日累加")
    func dailyTotalPrice() async throws {
        let client = stub()
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 3.50))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(roundedUSD: 1.10))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)] == Money(roundedUSD: 2.40))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("明细只留有钱的叶子，父类和 totalprice 丢掉")
    func linesKeepPricedLeaves() async throws {
        let snapshot = try await provider(stub()).fetch(credential: credential)
        let lines = try #require(snapshot.lines)
        #expect(lines.map(\.label) == ["Outbound SMS", "Outbound Calls", "Short Code Inbound SMS"])
        #expect(lines.map(\.category) == ["sms", "calls", "sms"])
        #expect(lines.allSatisfy { $0.scope == nil })

        let outbound = try #require(lines.first)
        #expect(outbound.amountUSD == Money(usd: 2))
        #expect(outbound.quantity == 100)
        #expect(outbound.unit == "messages")
        #expect(outbound.listUSD == nil)

        let inbound = try #require(lines.last)
        #expect(inbound.amountUSD == Money(usd: Decimal(string: "0.40")!))
        #expect(inbound.quantity == 20)
        #expect(inbound.unit == "messages")
        // 合计仍是 totalprice，不拿分类加总去替换。
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 3.50))
    }

    @Test("本月合计是 0 就不打分类")
    func skipsCategoryFetchWhenMonthIsZero() async throws {
        let client = stub(
            daily: LiveProviderHarness.json([
                "usage_records": [
                    ["category": "totalprice", "price": "0", "price_unit": "usd", "start_date": "2026-08-01"],
                ],
            ])
        )
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.lines == nil)
        #expect(client.urls.count == 1)
        #expect(client.urls.first?.path.hasSuffix("/Usage/Records/Daily.json") == true)
    }

    @Test("usage_unit 和价钱单位相同时不当成用量")
    func dropsQuantityWhenUsageRepeatsPrice() throws {
        let records = [
            record(category: "calls-outbound", description: "Outbound Calls", price: "1.10", unit: "usd", usage: "1.10"),
        ]
        let line = try #require(TwilioBillingProvider.lines(from: records).first)
        #expect(line.quantity == nil)
        #expect(line.unit == nil)
        #expect(line.amountUSD == Money(usd: Decimal(string: "1.10")!))
    }

    @Test("连字符前缀认定父类，第一段是产品线")
    func parentPrefixAndFamily() {
        #expect(TwilioBillingProvider.family(of: "sms-inbound-shortcode") == "sms")
        #expect(TwilioBillingProvider.family(of: "premiumsupport") == "premiumsupport")
        let categories: Set<String> = ["sms", "sms-inbound", "sms-inbound-shortcode"]
        #expect(TwilioBillingProvider.isParent("sms", among: categories))
        #expect(TwilioBillingProvider.isParent("sms-inbound", among: categories))
        #expect(!TwilioBillingProvider.isParent("sms-inbound-shortcode", among: categories))
    }

    @Test("认证走 API Key SID，路径仍用 Account SID")
    func usesAPIKeyBasicAuth() async throws {
        let client = stub()
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.requests.count == 2)
        let expected = TwilioBillingProvider.basicAuthorization(username: keySID, password: secret)
        for request in client.requests {
            #expect(request.url?.path.contains(sid) == true)
            #expect(request.url?.path.contains(keySID) == false)
            #expect(request.value(forHTTPHeaderField: "Authorization") == expected)
        }
        #expect(client.urls[0].path.hasSuffix("/Usage/Records/Daily.json"))
        #expect(client.urls[1].path.hasSuffix("/Usage/Records.json"))
    }

    @Test("缺 API Key SID 直接失败")
    func missingKeySID() async {
        let error = await #expect(throws: ProviderError.self) {
            try await provider(LiveProviderHarness.stub([])).fetch(
                credential: Credential(providerID: .twilio, fields: [
                    .accountID: sid,
                    .apiToken: secret,
                ])
            )
        }
        #expect(error?.code == .missingCredential)
    }

    @Test("非 usd 拒绝换算")
    func rejectsNonUSD() async {
        let client = stub(
            daily: LiveProviderHarness.json([
                "usage_records": [
                    ["price": "1", "price_unit": "eur", "start_date": "2026-08-01"],
                ],
            ]),
            categories: LiveProviderHarness.json(["usage_records": [] as [Any]])
        )
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
    }

    @Test("拉取更多历史拉长日线，本月合计和明细仍只数本月")
    func historyWidensDailyAndKeepsCurrentMonthTotal() async throws {
        let span = CalendarMonthWindow.spanning(
            for: .availableHistory,
            lookbackMonths: TwilioBillingProvider.descriptor.historyLookbackMonths,
            now: now,
            calendar: calendar
        )
        let client = LiveProviderHarness.stub([
            (
                TwilioBillingProvider.dailyURL(
                    accountSID: sid,
                    from: span.start,
                    to: now,
                    calendar: calendar
                ),
                LiveProviderHarness.json([
                    "usage_records": [
                        ["category": "totalprice", "price": "12", "price_unit": "usd", "start_date": "2026-07-05"],
                        ["category": "totalprice", "price": "1.10", "price_unit": "usd", "start_date": "2026-08-01"],
                    ],
                ])
            ),
            (
                TwilioBillingProvider.categoryURL(
                    accountSID: sid,
                    from: monthStart,
                    to: now,
                    calendar: calendar
                ),
                LiveProviderHarness.json([
                    "usage_records": [
                        [
                            "category": "sms-outbound",
                            "description": "Outbound SMS",
                            "price": "1.10",
                            "price_unit": "usd",
                            "usage": "10",
                            "usage_unit": "messages",
                        ],
                    ],
                ])
            ),
        ])
        let snapshot = try await provider(client).fetch(
            credential: credential,
            horizon: .availableHistory
        )
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "1.10")!))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 7, 5)] == Money(usd: 12))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(usd: Decimal(string: "1.10")!))
        #expect(snapshot.lines?.count == 1)
        #expect(snapshot.lines?.first?.amountUSD == Money(usd: Decimal(string: "1.10")!))
        #expect(client.urls.contains { $0.path.hasSuffix("/Usage/Records.json") })
        #expect(!client.urls.contains { url in
            url.path.hasSuffix("/Usage/Records.json") && url.query?.contains("StartDate=2025-") == true
        })
    }

    @Test("JPY 明细和合计走同一张汇率")
    func yenLinesScaleWithTotal() async throws {
        let client = stub(
            daily: LiveProviderHarness.json([
                "usage_records": [
                    ["category": "totalprice", "price": "1000", "price_unit": "jpy", "start_date": "2026-08-01"],
                ],
            ]),
            categories: LiveProviderHarness.json([
                "usage_records": [
                    [
                        "category": "sms-outbound",
                        "description": "Outbound SMS",
                        "price": "600",
                        "price_unit": "jpy",
                        "usage": "100",
                        "usage_unit": "messages",
                    ],
                    [
                        "category": "calls-outbound",
                        "description": "Outbound Calls",
                        "price": "400",
                        "price_unit": "jpy",
                        "usage": "10",
                        "usage_unit": "minutes",
                    ],
                ],
            ])
        )
        let rates = SharedExchangeRates(ExchangeRates(usdPerUnit: ["JPY": Decimal(string: "0.00655")!]))
        let snapshot = try await provider(client, rates: rates).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "6.55")!))
        let lines = try #require(snapshot.lines)
        #expect(lines.count == 2)
        #expect(lines[0].amountUSD == Money(usd: Decimal(string: "3.93")!))
        #expect(lines[1].amountUSD == Money(usd: Decimal(string: "2.62")!))
        #expect(lines.map(\.amountUSD).reduce(.zero, +) == snapshot.currentSpendUSD)
        #expect(snapshot.converted?.currency == "JPY")
    }

    @Test("EndDate 不超过 GMT 今天")
    func clampsEndDateToGMTToday() {
        let now = tokyoDate(2026, 8, 15, 8)
        let range = TwilioBillingProvider.queryDateRange(
            from: tokyoDate(2026, 8, 1),
            to: now,
            calendar: tokyo
        )
        #expect(range?.start == "2026-08-01")
        #expect(range?.end == "2026-08-14")
    }

    @Test("GMT 还没到本月 1 号时不打 Daily，本月是 $0")
    func localMonthStartBeforeGMTIsZeroUsage() async throws {
        let now = tokyoDate(2026, 9, 1, 8, 22)
        #expect(
            TwilioBillingProvider.queryDateRange(
                from: tokyoDate(2026, 9, 1),
                to: now,
                calendar: tokyo
            ) == nil
        )
        let client = LiveProviderHarness.stub([])
        let snapshot = try await provider(client, now: now, calendar: tokyo)
            .fetch(credential: credential)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
        #expect(snapshot.lines == nil)
        #expect(client.urls.isEmpty)
    }

    @Test("本月第一天 Daily 20404 当 $0")
    func singleDayDailyNotFoundIsZeroUsage() async throws {
        let now = LiveProviderHarness.date(2026, 9, 1, 1)
        let start = LiveProviderHarness.date(2026, 9, 1)
        let client = LiveProviderHarness.stub([
            (
                TwilioBillingProvider.dailyURL(accountSID: sid, from: start, to: now, calendar: calendar),
                LiveProviderHarness.json(
                    [
                        "code": 20404,
                        "message": "The requested resource /Usage/Records/Daily.json was not found",
                        "status": 404,
                    ] as [String: Any],
                    status: 404
                )
            ),
        ])
        let snapshot = try await provider(client, now: now).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.hasBillableMetrics)
        #expect(snapshot.lines == nil)
        #expect(client.urls.count == 1)
        #expect(client.urls.first?.path.hasSuffix("/Usage/Records/Daily.json") == true)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("整月 Daily 404 仍是账单接口不可用")
    func multiDayDailyNotFoundStillFails() async {
        let client = stub(daily: LiveProviderHarness.emptyJSON(status: 404))
        let error = await #expect(throws: ProviderError.self) {
            _ = try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .billingAPIUnavailable)
        #expect(error?.httpStatus == 404)
    }

    @Test("401 仍是凭据错误")
    func unauthorizedStillFails() async {
        let client = stub(daily: LiveProviderHarness.emptyJSON(status: 401))
        let error = await #expect(throws: ProviderError.self) {
            _ = try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unauthorized)
        #expect(error?.httpStatus == 401)
    }

    private var monthStart: Date { LiveProviderHarness.date(2026, 8, 1) }

    private var tokyo: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }

    private func tokyoDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return tokyo.date(from: components)!
    }

    private var credential: Credential {
        Credential(providerID: .twilio, fields: [
            .accountID: sid,
            .accessKeyID: keySID,
            .apiToken: secret,
        ])
    }

    private func stub(
        daily: StubHTTPResponse = LiveProviderHarness.body(LiveProviderHarness.fixture("twilio-usage-daily")),
        categories: StubHTTPResponse = LiveProviderHarness.body(LiveProviderHarness.fixture("twilio-usage-records"))
    ) -> RecordingHTTPClient {
        LiveProviderHarness.stub([
            (TwilioBillingProvider.dailyURL(accountSID: sid, from: monthStart, to: now, calendar: calendar), daily),
            (TwilioBillingProvider.categoryURL(accountSID: sid, from: monthStart, to: now, calendar: calendar), categories),
        ])
    }

    private func provider(
        _ client: any HTTPClient,
        now: Date? = nil,
        calendar: Calendar? = nil,
        rates: SharedExchangeRates = SharedExchangeRates(.usdOnly)
    ) -> TwilioBillingProvider {
        let now = now ?? self.now
        return TwilioBillingProvider(
            httpClient: client,
            now: { now },
            calendar: calendar ?? self.calendar,
            rateSource: rates
        )
    }

    private func record(
        category: String,
        description: String,
        price: String,
        unit: String,
        usage: String
    ) -> TwilioBillingProvider.Record {
        TwilioBillingProvider.Record(
            category: category,
            description: description,
            price: FlexibleDecimal(Decimal(string: price)!),
            price_unit: unit,
            usage: FlexibleDecimal(Decimal(string: usage)!),
            usage_unit: unit,
            start_date: nil,
            end_date: nil
        )
    }
}
