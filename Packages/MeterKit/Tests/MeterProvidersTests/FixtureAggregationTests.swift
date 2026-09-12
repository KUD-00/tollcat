import Foundation
import Testing
import MeterCore
@testable import MeterProviders

struct FixtureAggregationTests {
    private let calendar = LiveProviderHarness.calendar

    @Test("SPEC 第 04 节 fixture 加总 $47.20 且 confidence 不是 exact")
    func designFixturesSumToSpecTotal() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = try FixtureLoader.designSnapshots(now: now, calendar: calendar).map {
            var snapshot = $0
            snapshot.accountID = AccountID.fixture(for: snapshot.providerID)
            return snapshot
        }
        let result = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar
        )

        #expect(result.totalUSD == Money(roundedUSD: 47.20))
        #expect(result.confidence != .exact)
        #expect(result.confidence == .estimated)
        #expect(result.estimatedAccounts == [AccountID.fixture(for: .neon)])
        #expect(result.formattedTotal == "$47.20")
    }

    @Test("fixture 日期按传入月份展开，不写死 2026-08")
    func relativeDatesFollowTheClockMonth() throws {
        let now = LiveProviderHarness.date(2027, 3, 16, 12)
        let snapshot = try FixtureLoader.snapshot(for: .cloudflare, now: now, calendar: calendar)

        #expect(snapshot.periodStart == LiveProviderHarness.date(2027, 3, 1))
        #expect(snapshot.periodEnd == LiveProviderHarness.date(2027, 3, 31))
        #expect(snapshot.dailyUSD?.keys.contains(LiveProviderHarness.date(2027, 3, 1)) == true)
        #expect(snapshot.dailyUSD?.keys.contains(LiveProviderHarness.date(2026, 8, 1)) != true)
    }

    @Test("未接入的 fixture 不进入设计稿合计")
    func disconnectedFixturesAreOmittedFromDesignSet() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = try FixtureLoader.designSnapshots(now: now, calendar: calendar)
        let ids = Set(snapshots.map(\.providerID))

        #expect(!ids.contains(.fly))
        #expect(!ids.contains(.anthropic))
        #expect(try FixtureLoader.isConnected(.fly) == false)
        #expect(try FixtureLoader.isConnected(.anthropic) == false)
    }

    @Test("上月同期：AWS $13.20 → +62%，整体 $34.20 → +38%")
    func previousMonthSamePeriodMatchesDesignCopy() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))
        let result = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar
        )

        let aws = try #require(result.facts.first {
            $0.providerID == .aws && $0.type == .monthToDateUsage
        })
        #expect(aws.amountUSD == Money(roundedUSD: 21.40))
        #expect(aws.comparisonUSD == Money(roundedUSD: 13.20))
        #expect(Int(((aws.changeRatio ?? 0) * 100).rounded()) == 62)

        #expect(result.totalUSD == Money(roundedUSD: 47.20))
        #expect(result.comparisonUSD == Money(roundedUSD: 34.20))
        #expect(Int(((result.changeRatio ?? 0) * 100).rounded()) == 38)
        #expect(result.comparisonWindow?.month(calendar: calendar) == 7)
    }

    /// 设计稿的预充值余额曲线**必须单调下降**。
    ///
    /// 这份 fixture 原来在月中有一个比月初还高的点（月初 49.62、月中 58.33、
    /// 此刻 42）。那等于「充过一次值」，而本月消耗于是**至少**是最近一周掉的
    /// 16.33——不是 SPEC 里那个 7.62。它以前对得上，只因为当时的算法是
    /// 「月初 − 现在」，中间那个高点根本不看。
    ///
    /// 两个设计数字不可能同时成立：本月只花 7.62、又要按近 7 日速度 18 天见底，
    /// 意味着一周就要烧掉 16 块。SPEC 的合计 47.20 铺了五端和全部截图，
    /// 所以保它，续航跟着曲线走。
    @Test("OpenAI 按近 7 日速度还能用 43 天")
    func openaiRunwayFollowsTheDesignCurve() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))
        let runways = PrepaidRunwayCalculator.compute(
            snapshots: snapshots,
            now: now,
            calendar: calendar
        )

        let openai = try #require(runways.first { $0.providerID == .openai })
        #expect(openai.balanceUSD == Money(usd: 42))
        #expect(openai.daysRemaining == 43)
    }

    @Test("手动订阅 fixture 落在未来 7 天内，并计入本月合计")
    func upcomingManualSubscriptionIsIncludedInMonthToDate() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let subscriptions = try FixtureLoader.designSubscriptions(now: now, calendar: calendar)
        let extra = try #require(subscriptions.first)
        #expect(extra.name == "ChatGPT Plus")
        #expect(extra.amount == Money(usd: 20))

        let charges = UpcomingChargeCalculator.charges(
            snapshots: [],
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
        #expect(charges.count == 1)
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: charges[0].chargeDate)
        ).day
        #expect(days == 4)

        let snapshots = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))
        let withoutSubscription = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar
        )
        #expect(withoutSubscription.totalUSD == Money(roundedUSD: 47.20))

        let withSubscription = MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
        #expect(withSubscription.totalUSD == Money(roundedUSD: 67.20))
        #expect(
            withSubscription.facts.contains {
                $0.type == .subscriptionIncluded && $0.amountUSD == Money(usd: 20)
            }
        )
        #expect(Int(((withSubscription.changeRatio ?? 0) * 100).rounded()) == 96)
    }

    @Test("上月读数跟着传入月份走，不写死 2026-07")
    func previousMonthFollowsTheClockMonth() throws {
        let now = LiveProviderHarness.date(2027, 3, 16, 12)
        let snapshots = try FixtureLoader.snapshots(for: .aws, now: now, calendar: calendar)
        let previous = try #require(snapshots.first { calendar.component(.month, from: $0.fetchedAt) == 2 })
        #expect(calendar.component(.year, from: previous.fetchedAt) == 2027)
        #expect(previous.currentSpendUSD == Money(roundedUSD: 13.20))
    }

    @Test("AWS 日粒度从 9 号起明显上涨")
    func awsDailyJumpsFromDayNine() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshot = try FixtureLoader.snapshot(for: .aws, now: now, calendar: calendar)
        let daily = try #require(snapshot.dailyUSD)

        let early = (1...8).compactMap { daily[LiveProviderHarness.date(2026, 8, $0)] }
        let late = (9...16).compactMap { daily[LiveProviderHarness.date(2026, 8, $0)] }
        #expect(!early.isEmpty)
        #expect(!late.isEmpty)
        #expect(early.max()! < late.min()!)
        #expect(early.reduce(Money.zero, +) + late.reduce(Money.zero, +) == Money(roundedUSD: 21.40))
    }

    @Test("设计稿趋势：上月与本月都是非零点，仪表盘趋势瓷砖有柱可画")
    func designHistoryYieldsTwoNonZeroMonths() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))

        let points = MonthSpendHistoryCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar,
            monthCount: 2
        )

        #expect(points.count == 2)
        // 7 月 = AWS 13.20 + Cloudflare 8.50 + Neon 2.50 + OpenAI 预充值消耗 6.00
        #expect(calendar.component(.month, from: points[0].monthStart) == 7)
        #expect(points[0].variableUSD == Money(roundedUSD: 30.20))
        // 8 月 = 设计稿合计 47.20 里的从量部分（去掉 GitHub $4 档位）
        #expect(calendar.component(.month, from: points[1].monthStart) == 8)
        #expect(points[1].variableUSD == Money(roundedUSD: 43.20))
    }

    @Test("设计稿趋势：近 6 个月从量都有柱，当月和上月数字不动")
    func designHistoryFillsSixMonths() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let snapshots = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))

        let points = MonthSpendHistoryCalculator.compute(
            snapshots: snapshots,
            subscriptions: [],
            now: now,
            calendar: calendar,
            monthCount: 6
        )

        #expect(points.count == 6)
        #expect(points.map { calendar.component(.month, from: $0.monthStart) } == [3, 4, 5, 6, 7, 8])
        #expect(points.map(\.variableUSD) == [
            Money(roundedUSD: 18.00),
            Money(roundedUSD: 21.00),
            Money(roundedUSD: 24.00),
            Money(roundedUSD: 27.00),
            Money(roundedUSD: 30.20),
            Money(roundedUSD: 43.20),
        ])
    }

    // MARK: - 中国区那一套覆盖

    /// 覆盖存在的意义是「两套图共用一次构建」，所以它必须和默认那份**逐个数字对齐**：
    /// 合计一变，铺了五端的 SPEC 47.20 就跟着假掉，而截图上看不出来。
    @Test("cn 覆盖：合计与默认那份一致，只是换了家")
    func cnOverlayKeepsTheDesignTotals() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let usd = { (snapshots: [Snapshot]) in
            MonthToDateCalculator.compute(
                snapshots: snapshots,
                subscriptions: [],
                now: now,
                calendar: self.calendar
            ).totalUSD
        }
        let plain = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar))
        let cn = stamped(try FixtureLoader.designSnapshots(now: now, calendar: calendar, overlay: .cn))
        #expect(usd(cn) == usd(plain))
    }

    @Test("cn 覆盖：OpenAI 退成未接入，预付范例落在 DeepSeek 上")
    func cnOverlaySwapsThePrepaidExemplar() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        #expect(try FixtureLoader.isConnected(.openai) == true)
        #expect(try FixtureLoader.isConnected(.openai, overlay: .cn) == false)

        let runways = PrepaidRunwayCalculator.compute(
            snapshots: stamped(try FixtureLoader.designSnapshots(
                now: now,
                calendar: calendar,
                overlay: .cn
            )),
            now: now,
            calendar: calendar
        )
        #expect(runways.contains { $0.providerID == .openai } == false)
        let deepseek = try #require(runways.first { $0.providerID == .deepseek })
        #expect(deepseek.balanceUSD == Money(usd: 42))
        #expect(deepseek.daysRemaining == 43)
    }

    /// 这条是闸：覆盖里出现任何一个 Apple 会扫的名字，中国区那一轮就白跑。
    @Test("cn 覆盖：演示订阅不带 ChatGPT / Midjourney 字样")
    func cnOverlayNamesAreSafeForChina() throws {
        let now = LiveProviderHarness.date(2026, 8, 16, 12)
        let names = try FixtureLoader.designSubscriptions(
            now: now,
            calendar: calendar,
            overlay: .cn
        ).map(\.name)
        #expect(names.isEmpty == false)
        for banned in ["ChatGPT", "OpenAI", "Midjourney", "Anthropic", "Claude"] {
            #expect(names.contains { $0.localizedCaseInsensitiveContains(banned) } == false)
        }
    }

    private func stamped(_ snapshots: [Snapshot]) -> [Snapshot] {
        snapshots.map { snapshot in
            var copy = snapshot
            copy.accountID = AccountID.fixture(for: snapshot.providerID)
            return copy
        }
    }
}
