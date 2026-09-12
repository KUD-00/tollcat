import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct CloudflareBillingProviderTests {
    private let calendar = LiveProviderHarness.calendar
    private let now = LiveProviderHarness.now
    private let secret = "cf-token-MUST-NOT-LEAK"
    private let account = "023e105f4ecef8ad9ca31a8372d0c353"

    @Test("正常响应：数字和字符串金额都计入 dailyUSD")
    func successMapsDailySpend() async throws {
        let client = stubCurrent(LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage")))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.providerID == .cloudflare)
        #expect(snapshot.kind == .usage)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 11.05))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2026, 8, 31))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 1)] == Money(roundedUSD: 0.75))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 2)] == Money(roundedUSD: 10.30))
        #expect(client.urls.contains { $0.path.hasSuffix("/billable-usage") && $0.query == nil })
        #expect(client.urls.contains { $0.path.hasSuffix("/billable-usage/info") })
        #expect(OutboundHosts.contains(client.urls[0]))
        #expect(client.leakedSecrets([secret]).isEmpty)
        LiveProviderHarness.expectHostsDeclared(client)
    }

    @Test("明细按产品线分组，额度说明从服务名里拆出来")
    func linesGroupByServiceFamily() async throws {
        let client = stubCurrent(LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage")))
        let snapshot = try await provider(client).fetch(credential: credential)

        let lines = try #require(snapshot.lines)
        #expect(lines.map(\.category) == ["R2", "Workers", "Containers"])
        // Cloudflare 这条接口不按 zone / bucket 切，没有第二个归属维度。
        #expect(lines.allSatisfy { $0.scope == nil })

        let r2 = try #require(lines.first { $0.category == "R2" })
        #expect(r2.amountUSD == Money(usd: Decimal(string: "10.30")!))
        #expect(r2.listUSD == Money(usd: Decimal(string: "10.30")!))
        #expect(r2.quantity == Decimal(string: "42.5")!)
        #expect(r2.unit == "GB-months")
        #expect(r2.allowanceNote == nil)

        // 额度内那条：实收 0、原价有值、括号拆成额度说明，标题只留服务名。
        let containers = try #require(lines.first { $0.category == "Containers" })
        #expect(containers.label == "Container vCPU")
        #expect(containers.allowanceNote == "First 375 vCPU-minutes included")
        #expect(containers.amountUSD == .zero)
        #expect(containers.discountUSD == Money(usd: Decimal(string: "0.42")!))
    }

    @Test("同一服务分散在多天，明细合成一条，用量相加")
    func linesMergeAcrossDays() async throws {
        let payload: [String: Any] = [
            "success": true,
            "result": (1...3).map { day in
                [
                    "BilledCost": 0.5,
                    "ListCost": 1,
                    "BillingCurrency": "USD",
                    "ChargePeriodStart": String(format: "2026-08-%02dT00:00:00Z", day),
                    "ServiceFamilyName": "Workers KV",
                    "ServiceName": "KV List Operations (First 1M is included)",
                    "ConsumedQuantity": 1000,
                    "ConsumedUnit": "Count",
                ] as [String: Any]
            },
        ]
        let client = stubCurrent(LiveProviderHarness.json(payload))
        let snapshot = try await provider(client).fetch(credential: credential)

        let line = try #require(snapshot.lines?.first)
        #expect(snapshot.lines?.count == 1)
        #expect(line.label == "KV List Operations")
        #expect(line.allowanceNote == "First 1M is included")
        #expect(line.quantity == 3000)
        #expect(line.amountUSD == Money(usd: Decimal(string: "1.5")!))
        #expect(line.listUSD == Money(usd: 3))
    }

    @Test("明细只收本月：上一周期的行进日线，不进明细")
    func linesStayInsideCalendarMonth() async throws {
        let payload: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": 5,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-07-08T00:00:00Z",
                    "ChargePeriodStart": "2026-07-20T00:00:00Z",
                    "ServiceFamilyName": "R2",
                    "ServiceName": "R2 Storage",
                ],
                [
                    "BilledCost": 0.95,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-08-08T00:00:00Z",
                    "ChargePeriodStart": "2026-08-10T00:00:00Z",
                    "ServiceFamilyName": "Workers",
                    "ServiceName": "Workers Standard",
                ],
            ],
        ]
        let client = stubCurrent(LiveProviderHarness.json(payload))
        let snapshot = try await provider(client).fetch(credential: credential)

        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "0.95")!))
        // 日线两天都在（趋势要用），明细只有 8 月那条。
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 7, 20)] == Money(usd: 5))
        #expect(snapshot.lines?.map(\.category) == ["Workers"])
    }

    @Test("服务名里的括号只有写着 included / free 才拆")
    func onlyAllowanceParentheticalIsSplit() {
        #expect(
            CloudflareBillingProvider.splitAllowanceNote("Container vCPU (First 375 vCPU-minutes included)").name
                == "Container vCPU"
        )
        // 地区名里的逗号和括号不能被当成额度说明切掉。
        let regional = "Container Egress, Oceania, Taiwan, and Korea, per GB"
        #expect(CloudflareBillingProvider.splitAllowanceNote(regional).name == regional)
        #expect(CloudflareBillingProvider.splitAllowanceNote(regional).note == nil)
        let parenthesised = "Workers Paid (legacy)"
        #expect(CloudflareBillingProvider.splitAllowanceNote(parenthesised).name == parenthesised)
        #expect(CloudflareBillingProvider.splitAllowanceNote(parenthesised).note == nil)
    }

    @Test("1 号起的周期本月不跨段，不打上一周期")
    func firstOfMonthSkipsPreviousCycle() async throws {
        let client = stubCurrent(LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage")))
        _ = try await provider(client).fetch(credential: credential)
        #expect(client.urls.filter { $0.path.hasSuffix("/billable-usage") }.count == 1)
        #expect(client.urls.contains { $0.query?.contains("from=") == true } == false)
    }

    @Test("月中锚点会补上一周期，日历月合计每次相同")
    func midMonthCycleFillsCalendarMonthConsistently() async throws {
        let now = LiveProviderHarness.date(2026, 8, 26, 12)
        let cycle = CloudflareBillingCycle.containing(now: now, anchorDay: 16, calendar: calendar)
        let previous = cycle.preceding(calendar: calendar)
        let currentPayload: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": "5.21",
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-08-16T00:00:00Z",
                    "ChargePeriodStart": "2026-08-16T00:00:00Z",
                ],
            ],
        ]
        let previousPayload: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": "1.95",
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-07-16T00:00:00Z",
                    "ChargePeriodStart": "2026-08-10T00:00:00Z",
                ],
            ],
        ]
        let client = stub(
            usage: LiveProviderHarness.json(currentPayload),
            info: infoResponse(anchor: "2023-08-16T00:00:00Z"),
            periods: [
                (
                    previous,
                    LiveProviderHarness.json(previousPayload)
                ),
            ]
        )
        let first = try await provider(client, now: now).fetch(credential: credential)
        let second = try await provider(client, now: now).fetch(credential: credential)

        #expect(first.currentSpendUSD == Money(usd: Decimal(string: "7.16")!))
        #expect(second.currentSpendUSD == first.currentSpendUSD)
        #expect(first.periodStart == LiveProviderHarness.date(2026, 8, 16))
        #expect(first.periodEnd == LiveProviderHarness.date(2026, 9, 15))
        #expect(first.dailyUSD?[LiveProviderHarness.date(2026, 8, 10)] == Money(usd: Decimal(string: "1.95")!))
        #expect(first.dailyUSD?[LiveProviderHarness.date(2026, 8, 16)] == Money(usd: Decimal(string: "5.21")!))
        #expect(client.urls.contains { url in
            url.query?.contains("from=2026-07-16") == true
                && url.query?.contains("to=2026-08-15") == true
        })
    }

    @Test("不带日期那次已经盖到上一周期时，不再补一次、也不把重叠的天加两遍")
    func priorCycleAlreadyCoveredIsNotRefetched() async throws {
        // 真账号形状：锚点 8 号，不带日期回 7/8 起一直到今天，横跨两个周期。
        let now = LiveProviderHarness.date(2026, 8, 27, 12)
        var rows: [[String: Any]] = []
        var day = LiveProviderHarness.date(2026, 7, 8)
        while day <= LiveProviderHarness.date(2026, 8, 26) {
            let parts = calendar.dateComponents([.year, .month, .day], from: day)
            rows.append([
                "BilledCost": 0.5,
                "BillingCurrency": "USD",
                "BillingPeriodStart": day < LiveProviderHarness.date(2026, 8, 8)
                    ? "2026-07-08T00:00:00Z"
                    : "2026-08-08T00:00:00Z",
                "ChargePeriodStart": String(
                    format: "%04d-%02d-%02dT00:00:00Z",
                    parts.year ?? 0,
                    parts.month ?? 0,
                    parts.day ?? 0
                ),
            ])
            day = try #require(calendar.date(byAdding: .day, value: 1, to: day))
        }
        let cycle = CloudflareBillingCycle.containing(now: now, anchorDay: 8, calendar: calendar)
        let client = stub(
            usage: LiveProviderHarness.json(["success": true, "result": rows] as [String: Any]),
            info: infoResponse(anchor: "2025-08-08T00:00:00Z"),
            periods: [(
                cycle.preceding(calendar: calendar),
                LiveProviderHarness.json(["success": true, "result": rows] as [String: Any])
            )]
        )
        let snapshot = try await provider(client, now: now).fetch(credential: credential)

        // 8/1–8/26 共 26 天 × 0.5，补那次要么没发、要么被按天挡掉，都不该翻倍。
        #expect(snapshot.currentSpendUSD == Money(usd: 13))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 5)] == Money(usd: Decimal(string: "0.5")!))
        #expect(client.urls.contains { $0.query?.contains("from=") == true } == false)
    }

    @Test("periodStart 用当前周期，不拿上一周期最后一行的 BillingPeriodStart")
    func periodStartIsCurrentCycleNotLastRow() async throws {
        let now = LiveProviderHarness.date(2026, 8, 26, 12)
        let cycle = CloudflareBillingCycle.containing(now: now, anchorDay: 16, calendar: calendar)
        let mixed: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": 1.95,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-07-16T00:00:00Z",
                    "ChargePeriodStart": "2026-08-10T00:00:00Z",
                ],
                [
                    "BilledCost": 5.21,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-08-16T00:00:00Z",
                    "ChargePeriodStart": "2026-08-16T00:00:00Z",
                ],
            ],
        ]
        let client = stub(
            usage: LiveProviderHarness.json(mixed),
            info: infoResponse(anchor: "2023-08-16T00:00:00Z"),
            periods: [(cycle.preceding(calendar: calendar), LiveProviderHarness.json(emptyResult))]
        )
        let snapshot = try await provider(client, now: now).fetch(credential: credential)
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 16))
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "7.16")!))
    }

    @Test("历史按周期一段一段拉，不把两个锚点塞进同一次 from/to")
    func historyLookbackQueriesEachCycle() async throws {
        let cycle = CloudflareBillingCycle.containing(
            now: now,
            anchor: LiveProviderHarness.date(2023, 1, 1),
            calendar: calendar
        )
        let window = CalendarMonthWindow.current(now: now, calendar: calendar)
        let extras = CloudflareBillingProvider.extraPeriods(
            for: .availableHistory,
            cycle: cycle,
            window: window,
            calendar: calendar
        )
        #expect(extras.count == 12)
        #expect(extras.allSatisfy { $0.start < cycle.start })
        for period in extras {
            let days = calendar.dateComponents([.day], from: period.start, to: period.nextStart).day ?? .max
            #expect(days <= 31)
            #expect(period.start < period.nextStart)
        }
        for (first, second) in zip(extras.reversed(), extras.reversed().dropFirst()) {
            #expect(first.nextStart == second.start)
        }

        let client = stub(
            usage: LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage")),
            periods: extras.map { ($0, LiveProviderHarness.json(emptyResult)) }
        )
        let snapshot = try await provider(client).fetch(
            credential: credential,
            horizon: .availableHistory
        )
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 11.05))
        let dated = client.urls.filter { $0.query?.contains("from=") == true }
        #expect(dated.count == 12)
        #expect(dated.allSatisfy { url in
            !(url.query?.contains("from=2025-08-16") == true && url.query?.contains("to=2026-09-01") == true)
        })
    }

    @Test("跨周期的日粒度只把本月几天计入 currentSpendUSD")
    func calendarMonthSpendIgnoresPriorCycleDays() async throws {
        let payload: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": 5,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-07-08T00:00:00Z",
                    "ChargePeriodStart": "2026-07-20T00:00:00Z",
                ],
                [
                    "BilledCost": 0.95,
                    "BillingCurrency": "USD",
                    "BillingPeriodStart": "2026-08-08T00:00:00Z",
                    "ChargePeriodStart": "2026-08-10T00:00:00Z",
                ],
            ],
        ]
        let client = stubCurrent(LiveProviderHarness.json(payload))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "0.95")!))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 7, 20)] == Money(usd: 5))
        #expect(snapshot.dailyUSD?[LiveProviderHarness.date(2026, 8, 10)] == Money(usd: Decimal(string: "0.95")!))
    }

    @Test("info 404 时从 BillingPeriodStart 推断周期")
    func missingInfoInfersCycleFromRows() async throws {
        let client = LiveProviderHarness.stub([
            (usageURL(from: nil, to: nil), LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage"))),
            (
                CloudflareBillingProvider.billableUsageInfoURL(accountID: account),
                LiveProviderHarness.emptyJSON(status: 404)
            ),
        ])
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == Money(roundedUSD: 11.05))
        #expect(snapshot.periodStart == LiveProviderHarness.date(2026, 8, 1))
    }

    @Test("空 result 是 $0，不是失败")
    func emptyResultIsZero() async throws {
        let client = stubCurrent(LiveProviderHarness.json(emptyResult))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
        #expect(snapshot.dailyUSD?.isEmpty == true)
    }

    @Test("401 / 403 映射到不同 RemediationKey")
    func unauthorizedAndForbidden() async {
        await expectStatus(401, code: .unauthorized, key: .invalidCredentials)
        await expectStatus(403, code: .forbidden, key: .insufficientPermissions)
    }

    @Test("429 是限流，5xx 是对方故障")
    func rateLimitAndServerError() async {
        await expectStatus(429, code: .rateLimited, key: .rateLimited)
        await expectStatus(503, code: .serviceUnavailable, key: .serviceUnavailable)
    }

    @Test("缺 BilledCost 的行跳过，整份没有金额字段则记 0")
    func missingCostFields() async throws {
        let payload: [String: Any] = [
            "success": true,
            "result": [
                ["ServiceName": "Workers", "BillingCurrency": "USD", "ChargePeriodStart": "2026-08-01T00:00:00Z"],
            ],
        ]
        let client = stubCurrent(LiveProviderHarness.json(payload))
        let snapshot = try await provider(client).fetch(credential: credential)
        #expect(snapshot.currentSpendUSD == .zero)
    }

    @Test("非 USD 拒绝换算")
    func rejectsNonUSD() async {
        let payload: [String: Any] = [
            "success": true,
            "result": [
                [
                    "BilledCost": 10,
                    "BillingCurrency": "EUR",
                    "ChargePeriodStart": "2026-08-01T00:00:00Z",
                ],
            ],
        ]
        let client = stubCurrent(LiveProviderHarness.json(payload))
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(credential: credential)
        }
        #expect(error?.code == .unsupportedCurrency)
        #expect(error?.remediationKey == .unsupportedCurrency)
    }

    @Test("缺少 token 或 account id")
    func missingCredential() async {
        let client = LiveProviderHarness.stub([])
        let error = await #expect(throws: ProviderError.self) {
            try await provider(client).fetch(
                credential: Credential(providerID: .cloudflare, fields: [.apiToken: secret])
            )
        }
        #expect(error?.code == .missingCredential)
        #expect(error?.remediationKey == .missingCredential)
    }

    private func expectStatus(
        _ status: Int,
        code: ProviderError.Code,
        key: RemediationKey
    ) async {
        await LiveProviderHarness.expectStatus(status, code: code, key: key) { status in
            let client = LiveProviderHarness.stub([
                (usageURL(from: nil, to: nil), LiveProviderHarness.emptyJSON(status: status)),
            ])
            return try await provider(client).fetch(credential: credential)
        }
    }

    private var credential: Credential {
        Credential(providerID: .cloudflare, fields: [.apiToken: secret, .accountID: account])
    }

    private var emptyResult: [String: Any] {
        ["success": true, "result": [] as [Any]]
    }

    private func provider(_ client: any HTTPClient, now: Date? = nil) -> CloudflareBillingProvider {
        let clock = now ?? self.now
        return CloudflareBillingProvider(
            httpClient: client,
            now: { clock },
            calendar: calendar,
            rateSource: SharedExchangeRates(.usdOnly)
        )
    }

    private func stubCurrent(_ usage: StubHTTPResponse) -> RecordingHTTPClient {
        stub(usage: usage)
    }

    private func stub(
        usage: StubHTTPResponse,
        info: StubHTTPResponse? = nil,
        periods: [(CloudflareBillingCycle, StubHTTPResponse)] = []
    ) -> RecordingHTTPClient {
        var pairs: [(URL, StubHTTPResponse)] = [
            (usageURL(from: nil, to: nil), usage),
            (
                CloudflareBillingProvider.billableUsageInfoURL(accountID: account),
                info ?? LiveProviderHarness.body(LiveProviderHarness.fixture("cloudflare-billable-usage-info"))
            ),
        ]
        for (period, response) in periods {
            pairs.append((
                usageURL(from: period.start, to: period.endInclusive(calendar: calendar)),
                response
            ))
        }
        return LiveProviderHarness.stub(pairs)
    }

    private func infoResponse(anchor: String) -> StubHTTPResponse {
        LiveProviderHarness.json([
            "success": true,
            "result": [
                "covered": true,
                "subscriptions": [
                    [
                        "id": "3F3CD4CQ6N7FXO7IK6NVFJBOYA",
                        "billing_cycle_anchor_timestamp": anchor,
                        "start_timestamp": anchor,
                    ],
                ],
            ],
        ] as [String: Any])
    }

    private func usageURL(from: Date?, to: Date?) -> URL {
        CloudflareBillingProvider.billableUsageURL(
            accountID: account,
            from: from,
            to: to,
            calendar: calendar
        )
    }
}
