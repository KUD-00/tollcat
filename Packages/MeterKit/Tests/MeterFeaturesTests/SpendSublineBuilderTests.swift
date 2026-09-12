import Foundation
import Testing
import MeterCore
@testable import MeterFeatures
@testable import MeterModules

struct SpendSublineBuilderTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private var comparisonWindow: ComparisonWindow {
        ComparisonWindow(start: date(2026, 7, 1), end: date(2026, 7, 16, 12), dayOfMonth: 16)
    }

    private func line(_ category: String, amount: Decimal) -> SpendLine {
        SpendLine(category: category, label: category, amountUSD: Money(usd: amount))
    }

    private func snapshot(
        accountID: AccountID,
        fetchedAt: Date,
        lines: [SpendLine]?
    ) -> Snapshot {
        Snapshot(
            providerID: .cloudflare,
            accountID: accountID,
            kind: .usage,
            fetchedAt: fetchedAt,
            periodStart: Date(timeIntervalSince1970: 0),
            periodEnd: Date(timeIntervalSince1970: 86_400),
            lines: lines
        )
    }

    private func byAttribution(
        snapshots: [Snapshot] = [],
        subscriptions: [MonthlySubscription] = [],
        asOf: Date? = nil,
        comparisonWindow: ComparisonWindow? = nil
    ) -> [SpendAttribution: [SpendSubline]] {
        // 子行现在收**现成的明细**——挑哪一份是账本折叠时的事。
        // 测试仍然从快照出发，只是先折一遍读模型，这样"挑"的那条规则也一并被覆盖。
        let at = asOf ?? date(2026, 8, 16)
        let view = LedgerView(
            rollups: LedgerSelfCheck.foldAll(snapshots: snapshots, now: at, calendar: calendar),
            subscriptions: subscriptions
        )
        return SpendSublineBuilder.byAttribution(
            lines: view.lines(onOrBefore: at),
            previousLines: comparisonWindow.map {
                view.lines(onOrBefore: $0.end, notBefore: $0.start)
            } ?? [:],
            subscriptions: subscriptions,
            connections: [],
            asOf: at,
            calendar: calendar,
            presentation: .usd,
            comparisonWindow: comparisonWindow
        )
    }

    @Test("只留花了钱的类别，按金额从大到小")
    func dropsFreeLinesAndSortsDescending() {
        let sublines = SpendSublineBuilder.make(
            lines: [
                line("Workers", amount: 1),
                line("R2", amount: 0),
                line("Pages", amount: 3),
                line("Workers", amount: 2),
            ],
            presentation: .usd
        )
        #expect(sublines.map(\.title) == ["Pages", "Workers"])
        #expect(sublines.map(\.amountCaption) == ["$3.00", "$3.00"])
    }

    @Test("全被额度抵掉的家不出子行")
    func allFreeMeansNoSublines() {
        #expect(SpendSublineBuilder.make(lines: [line("R2", amount: 0)], presentation: .usd).isEmpty)
    }

    @Test("超出上限的尾巴并成「其他」，钱不丢")
    func tailCollapsesIntoOther() {
        let lines = (1...8).map { line("cat\($0)", amount: Decimal($0)) }
        let sublines = SpendSublineBuilder.make(lines: lines, presentation: .usd)
        #expect(sublines.count == SpendSublineBuilder.maxSublines)
        // 8+7+6+5+4 留名，3+2+1 并进「其他」。
        #expect(sublines.last?.amountCaption == "$6.00")
        #expect(sublines.prefix(5).map(\.amountCaption) == ["$8.00", "$7.00", "$6.00", "$5.00", "$4.00"])
    }

    @Test("明细取最新一条带明细的快照，不合并历次")
    func picksLatestSnapshotWithLines() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: Date(timeIntervalSince1970: 100),
                    lines: [line("Workers", amount: 5)]
                ),
                snapshot(
                    accountID: id,
                    fetchedAt: Date(timeIntervalSince1970: 200),
                    lines: [line("Workers", amount: 7)]
                ),
                // 更新但不带明细的快照不抢位——历史窗口那次刷新不写明细。
                snapshot(
                    accountID: id,
                    fetchedAt: Date(timeIntervalSince1970: 300),
                    lines: nil
                ),
            ]
        )
        #expect(map[.account(id)]?.map(\.amountCaption) == ["$7.00"])
    }

    @Test("没有一条花钱的明细时账号不进 map，界面不出空组")
    func accountWithOnlyFreeLinesIsAbsent() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: Date(timeIntervalSince1970: 100),
                    lines: [line("R2", amount: 0)]
                ),
            ]
        )
        #expect(map.isEmpty)
    }

    @Test("挂厂商的订阅逐笔进 vendor 段，×N 写进名字")
    func vendorSubscriptionsListedIndividually() {
        let map = byAttribution(subscriptions: [
            MonthlySubscription(
                name: "SuperGrok",
                amount: Money(usd: 30),
                period: .monthly,
                anchorDate: date(2026, 7, 3),
                providerID: .xai
            ),
            MonthlySubscription(
                name: "Copilot Business",
                amount: Money(usd: 57),
                period: .monthly,
                anchorDate: date(2026, 7, 3),
                providerID: .xai,
                quantity: 3
            ),
        ])
        #expect(map[.vendor(.xai)]?.map(\.title) == ["Copilot Business ×3", "SuperGrok"])
        #expect(map[.vendor(.xai)]?.map(\.amountCaption) == ["$57.00", "$30.00"])
    }

    @Test("年付非周年月本月计 0，不占行；完全不归属的进手动订阅段")
    func annualOffMonthExcludedAndManualBucketed() {
        let map = byAttribution(subscriptions: [
            // asOf 是 8 月，周年月是 3 月：本月没扣，不该出现在子行里。
            MonthlySubscription(
                name: "1Password",
                amount: Money(usd: 36),
                period: .annual,
                anchorDate: date(2026, 3, 1)
            ),
            MonthlySubscription(
                name: "Setapp",
                amount: Money(usd: 10),
                period: .monthly,
                anchorDate: date(2026, 7, 1)
            ),
        ])
        #expect(map[.manual]?.map(\.title) == ["Setapp"])
    }

    @Test("厂商只有一个已接账号时，无主订阅并进那个账号，不另开 vendor 段")
    func vendorSubscriptionMergesIntoSoleAccount() {
        let id = AccountID.fixture(for: .xai)
        let map = SpendSublineBuilder.byAttribution(
            lines: [:],
            subscriptions: [
                MonthlySubscription(
                    name: "SuperGrok",
                    amount: Money(usd: 30),
                    period: .monthly,
                    anchorDate: date(2026, 7, 3),
                    providerID: .xai
                )
            ],
            connections: [
                ProviderConnectionState(
                    accountID: id,
                    providerID: .xai,
                    isEnabled: true,
                    sortIndex: 0,
                    credentialReference: "ref.\(id.rawValue.uuidString)",
                    includeInGlobalRefresh: true
                )
            ],
            asOf: date(2026, 8, 16),
            calendar: calendar,
            presentation: .usd
        )
        #expect(map[.account(id)]?.map(\.title) == ["SuperGrok"])
        #expect(map[.vendor(.xai)] == nil)
    }

    @Test("回看时不取 asOf 之后的明细")
    func ignoresSnapshotsAfterAsOf() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: date(2026, 7, 31),
                    lines: [line("Workers", amount: 5)]
                ),
                snapshot(
                    accountID: id,
                    fetchedAt: date(2026, 8, 16),
                    lines: [line("Workers", amount: 9)]
                ),
            ],
            asOf: date(2026, 7, 31)
        )
        #expect(map[.account(id)]?.map(\.amountCaption) == ["$5.00"])
    }

    @Test("同窗口内刷到过的类别带上同期涨跌")
    func comparesCategoriesWhenBothPeriodsHaveLines() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: date(2026, 7, 16, 12),
                    lines: [
                        line("Workers KV", amount: 1.1),
                        line("R2", amount: 0.8),
                    ]
                ),
                snapshot(
                    accountID: id,
                    fetchedAt: date(2026, 8, 16, 12),
                    lines: [
                        line("Workers KV", amount: 3.2),
                        line("Workers", amount: 2),
                    ]
                ),
            ],
            asOf: date(2026, 8, 16, 12),
            comparisonWindow: comparisonWindow
        )
        let rows = map[.account(id)] ?? []
        let kv = rows.first { $0.title == "Workers KV" }
        #expect(kv?.changeCaption == "+191%")
        #expect(kv?.comparisonSubtitle?.contains("1.10") == true)
        #expect(kv?.comparisonSubtitle?.contains("3.20") == true)
        let workers = rows.first { $0.title == "Workers" }
        #expect(workers?.changeCaption == nil)
        #expect(workers?.amountCaption == "$2.00")
        #expect(rows.contains { $0.title == "R2" } == false)
    }

    @Test("窗口里没有同期明细时子行只写本月")
    func skipsLineComparisonWithoutWindowSnapshot() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: date(2026, 8, 16, 12),
                    lines: [line("Workers KV", amount: 3.2)]
                ),
            ],
            asOf: date(2026, 8, 16, 12),
            comparisonWindow: comparisonWindow
        )
        #expect(map[.account(id)]?.first?.changeCaption == nil)
    }

    @Test("月付订阅两边同额时子行写持平")
    func monthlySubscriptionComparesFlat() {
        let map = byAttribution(
            subscriptions: [
                MonthlySubscription(
                    name: "Workers Paid",
                    amount: Money(usd: 5),
                    period: .monthly,
                    anchorDate: date(2026, 6, 1)
                ),
            ],
            comparisonWindow: comparisonWindow
        )
        #expect(map[.manual]?.first?.changeCaption == String(localized: MeterFeatures.L("持平")))
        #expect(map[.manual]?.first?.comparisonSubtitle?.contains("5.00") == true)
    }

    @Test("挂账号的订阅和该账号的用量类别合在同一段里排序")
    func accountSubscriptionsMergeWithUsage() {
        let id = AccountID.fixture(for: .cloudflare)
        let map = byAttribution(
            snapshots: [
                snapshot(
                    accountID: id,
                    fetchedAt: Date(timeIntervalSince1970: 100),
                    lines: [line("Workers", amount: 5)]
                ),
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "Workers Paid",
                    amount: Money(usd: 25),
                    period: .monthly,
                    anchorDate: date(2026, 7, 1),
                    accountID: id,
                    providerID: .cloudflare
                ),
            ]
        )
        #expect(map[.account(id)]?.map(\.title) == ["Workers Paid", "Workers"])
    }
}
