import Foundation
import Testing
import MeterCore
@testable import MeterFeatures
@testable import MeterModules

struct ComparisonBuilderTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("有上月从量时给出涨幅")
    func reportsIncrease() {
        var windowStart = DateComponents()
        windowStart.year = 2026
        windowStart.month = 7
        windowStart.day = 1
        let start = calendar.date(from: windowStart)!
        let content = ComparisonBuilder.make(
            from: MonthToDate(
                totalUSD: Money(roundedUSD: 47.2),
                projectedMonthEndUSD: Money(roundedUSD: 47.2),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .aws,
                        accountID: AccountID.fixture(for: .aws),
                        kind: .usage,
                        amountUSD: Money(roundedUSD: 47.2),
                        comparisonUSD: Money(roundedUSD: 29.1),
                        changeRatio: 0.621993,
                        confidence: .exact,
                        type: .monthToDateUsage
                    )
                ],
                comparisonUSD: Money(roundedUSD: 29.1),
                changeRatio: 0.621993,
                comparisonWindow: ComparisonWindow(start: start, end: start, dayOfMonth: 16),
                variableUSD: Money(roundedUSD: 47.2),
                projectedVariableUSD: Money(roundedUSD: 47.2)
            ),
            calendar: calendar
        )
        #expect(content.tone == .up)
        #expect(content.percentText.hasPrefix("+"))
        #expect(content.tone != .unknown)
        #expect(content.items.count == 1)
        #expect(content.incomparableItems.isEmpty)
    }

    @Test("一家缺同期时本月金额仍进合计涨幅")
    func reportsOverlapWhenOneProviderLacksHistory() {
        var windowStart = DateComponents()
        windowStart.year = 2026
        windowStart.month = 7
        windowStart.day = 1
        let start = calendar.date(from: windowStart)!
        let content = ComparisonBuilder.make(
            from: MonthToDate(
                totalUSD: Money(usd: 30),
                projectedMonthEndUSD: Money(usd: 30),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .aws,
                        accountID: AccountID.fixture(for: .aws),
                        kind: .usage,
                        amountUSD: Money(usd: 20),
                        comparisonUSD: Money(usd: 10),
                        changeRatio: 1,
                        confidence: .exact,
                        type: .monthToDateUsage
                    ),
                    Fact(
                        providerID: .neon,
                        accountID: AccountID.fixture(for: .neon),
                        kind: .usage,
                        amountUSD: Money(usd: 10),
                        confidence: .exact,
                        type: .monthToDateUsage
                    ),
                ],
                comparisonUSD: Money(usd: 10),
                changeRatio: 1,
                comparisonWindow: ComparisonWindow(start: start, end: start, dayOfMonth: 16),
                variableUSD: Money(usd: 30),
                projectedVariableUSD: Money(usd: 30)
            ),
            calendar: calendar
        )
        #expect(content.tone == .up)
        #expect(content.percentText == "+200%")
        #expect(content.current == 30)
        #expect(content.previous == 10)
        #expect(content.caption == content.windowCaption)
        #expect(content.windowCaption.split(separator: "·").count >= 3)
        #expect(content.comparableItems.map(\.providerID) == [.aws])
        #expect(content.incomparableItems.map(\.providerID) == [.neon])
    }

    @Test("对比页从右侧推进，不就地展开")
    func detailPushesFromTheDashboard() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Dashboard")
        // 模块视图搬去了 MeterModules（widget 才链得到），源码扫描跟着走。
        let modules = root
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "MeterModules")
        let dashboard = try String(
            contentsOf: root.appending(path: "DashboardView.swift"),
            encoding: .utf8
        )
        let detail = try String(
            contentsOf: root.appending(path: "ComparisonDetailView.swift"),
            encoding: .utf8
        )
        let tiles = try String(
            contentsOf: root.appending(path: "DashboardBentoTiles.swift"),
            encoding: .utf8
        )
        #expect(dashboard.contains("open(.comparison)"))
        #expect(dashboard.contains("path.append(route)"))
        #expect(dashboard.contains("macStack.push("))
        #expect(dashboard.contains("ComparisonDetailView"))
        #expect(!detail.contains(".sheet(isPresented:"))
        // 行推详情走 DashboardRouteLink：iPhone / iPad 系统栈，Mac 列内手工栈。
        #expect(detail.contains("DashboardRouteLink(route: .account"))
        #expect(detail.contains("DashboardRouteLink(route: .provider"))
        #expect(detail.contains("changeCaption"))
        #expect(detail.contains("comparisonSubtitle"))
        #expect(detail.contains("没有上月同一段日子的按量花费。本月金额已经算进上面的柱和涨跌幅。"))
        #expect(tiles.contains("onOpenComparison"))
        #expect(tiles.contains("meterListRowHitTarget"))
    }

    @Test("缺上月从量时方卡仍在，只是还不能对比")
    func unknownWhenNoHistory() {
        let content = ComparisonBuilder.make(
            from: MonthToDate(
                totalUSD: Money(usd: 10),
                projectedMonthEndUSD: Money(usd: 10),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .aws,
                        accountID: AccountID.fixture(for: .aws),
                        kind: .usage,
                        amountUSD: Money(usd: 10),
                        confidence: .exact,
                        type: .monthToDateUsage
                    )
                ],
                variableUSD: Money(usd: 10),
                projectedVariableUSD: Money(usd: 10)
            ),
            calendar: calendar
        )
        #expect(content.tone == .unknown)
        #expect(content.percentText == "—")
        #expect(content.current == 10)
        #expect(content.incomparableItems.map(\.providerID) == [.aws])
        #expect(content.comparableItems.isEmpty)
    }

    @Test("近几个月横轴右端越过本月，本月柱才落在卡内")
    func trendDomainEndIsExclusive() {
        let now = date(2026, 8, 16, 12)
        var daily: [Date: Money] = [:]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }
        // `TrendBuilder` 现在收现成的逐月数据——怎么算出来的（读账本还是扫快照）
        // 是调用方的事，这条测试守的是横轴右端，和数据从哪来无关。
        let history = MonthSpendHistoryCalculator.compute(
            snapshots: [
                Snapshot(
                    providerID: .cloudflare,
                    accountID: AccountID.fixture(for: .cloudflare),
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        let content = TrendBuilder.make(
            history: history,
            calendar: calendar,
            filter: .unfiltered
        )
        let end = try? #require(content?.xEnd)
        #expect(content?.highlight == date(2026, 8, 1))
        #expect(calendar.component(.month, from: end ?? .distantPast) == 9)
        #expect(calendar.component(.day, from: end ?? .distantPast) == 1)
    }

    @Test("近几个月方卡源码没有点进去")
    func trendTileIsNotADetailEntry() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Dashboard")
        // 模块视图搬去了 MeterModules（widget 才链得到），源码扫描跟着走。
        let modules = root
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "MeterModules")
        let tiles = try String(contentsOf: root.appending(path: "DashboardBentoTiles.swift"), encoding: .utf8)
        let tile = try String(contentsOf: modules.appending(path: "TrendTileView.swift"), encoding: .utf8)
        #expect(!tile.contains("onOpen"))
        #expect(!tile.contains("NavigationLink"))
        #expect(!tile.contains("chevron.right"))
        #expect(tiles.contains("TrendTileView(content: trend)"))
        #expect(!tiles.contains("onOpenTrend"))
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }
}
