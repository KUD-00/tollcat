import Foundation
import Testing
@testable import MeterCore

struct MonthToDateCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    // MARK: - 四条折算规则

    @Test("用量后付费：有日粒度则求和本月各天，精度 exact")
    func usageDailySumsCurrentMonthExactly() {
        let now = date(2026, 8, 16, 12)
        var daily: [Date: Money] = [
            date(2026, 7, 31): Money(usd: 9),
            date(2026, 8, 17): Money(usd: 5),
        ]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 16))
        #expect(result.confidence == .exact)
        #expect(result.estimatedAccounts.isEmpty)
        #expect(result.formattedTotal == "$16.00")
        #expect(result.facts.contains {
            $0.providerID == .cloudflare
                && $0.type == .monthToDateUsage
                && $0.kind == .usage
                && $0.amountUSD == Money(usd: 16)
        })
    }

    @Test("用量后付费：只有周期累计则按周期内天数线性摊到本月，精度 estimated")
    func usagePeriodTotalProratesAndIsEstimated() {
        let now = date(2026, 8, 10, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 17),
                    periodEnd: date(2026, 8, 16),
                    currentSpendUSD: Money(usd: 50)
                )
            ],
            now: now
        )

        // 周期已过日：7/17–8/10 共 25 天，落在 8 月的 10 天 → 50 × 10/25 = 20
        #expect(result.totalUSD == Money(usd: 20))
        #expect(result.confidence == .estimated)
        #expect(result.estimatedAccounts == [AccountID.fixture(for: .aws)])
        #expect(result.formattedTotal == "$20.00")
    }

    @Test("预充值余额：本月消耗 = 月初余额 − 当前余额")
    func prepaidUsesMonthStartMinusCurrent() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: date(2026, 7, 31, 23, 59),
                    balanceUSD: Money(usd: 100)
                ),
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: now,
                    balanceUSD: Money(usd: 42)
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 58))
        #expect(result.confidence == .exact)
        #expect(result.estimatedAccounts.isEmpty)
    }

    @Test("免费额度内：计 0，额度比例单独带在 facts 里")
    func freeTierCountsZeroAndExposesRatio() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .vercel,
                    kind: .freeTier,
                    fetchedAt: now,
                    freeQuotaUsedRatio: 0.34
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.confidence == .exact)
        #expect(result.facts.contains {
            $0.providerID == .vercel
                && $0.type == .freeQuota
                && $0.kind == .freeTier
                && $0.amountUSD == .zero
                && $0.freeQuotaUsedRatio == 0.34
        })
    }

    @Test("预充值中途充值：逐段做差，充上去的那一截不抵消已经花掉的")
    func prepaidTopUpDoesNotCancelWhatWasSpent() {
        // 7/31 $100 → 8/10 $80（花了 20）→ 8/15 充到 $180 → 8/20 $150（又花了 30）。
        // 「月初 − 现在」= 100 − 150 < 0，钳成 $0：这个月花的 $50 整个消失，
        // 而 confidence 还写着 exact。
        let now = date(2026, 8, 20, 12)
        let result = compute(
            snapshots: [
                snapshot(.openai, kind: .prepaid, fetchedAt: date(2026, 7, 31, 23, 59), balanceUSD: Money(usd: 100)),
                snapshot(.openai, kind: .prepaid, fetchedAt: date(2026, 8, 10, 9), balanceUSD: Money(usd: 80)),
                snapshot(.openai, kind: .prepaid, fetchedAt: date(2026, 8, 15, 9), balanceUSD: Money(usd: 180)),
                snapshot(.openai, kind: .prepaid, fetchedAt: now, balanceUSD: Money(usd: 150)),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 50))
        // 看见过充值就不能再说 exact：两次观测之间「先花再充」的那一截看不见，
        // 这个数字是下限。
        #expect(result.confidence == .partial)
    }

    @Test("预充值没充过值时，逐段做差和「月初 − 现在」是同一个数")
    func prepaidWithoutTopUpMatchesTheSimpleDifference() {
        let now = date(2026, 8, 20, 12)
        let result = compute(
            snapshots: [
                snapshot(.openai, kind: .prepaid, fetchedAt: date(2026, 7, 31, 23, 59), balanceUSD: Money(usd: 100)),
                snapshot(.openai, kind: .prepaid, fetchedAt: date(2026, 8, 10, 9), balanceUSD: Money(usd: 80)),
                snapshot(.openai, kind: .prepaid, fetchedAt: now, balanceUSD: Money(usd: 42)),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 58))
        #expect(result.confidence == .exact)
    }

    // MARK: - 精度组合

    @Test("四家都精确时，总体是 exact")
    func allExactProvidersStayExact() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 11.05)]
                ),
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 1),
                    balanceUSD: Money(usd: 50)
                ),
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: now,
                    balanceUSD: Money(roundedUSD: 42.38)
                ),
                snapshot(
                    .github,
                    kind: .subscription,
                    fetchedAt: now,
                    committedMonthlyUSD: Money(usd: 4),
                    chargeDayOfMonth: 3
                ),
                snapshot(
                    .vercel,
                    kind: .freeTier,
                    fetchedAt: now,
                    freeQuotaUsedRatio: 0.34
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(roundedUSD: 22.67))
        #expect(result.confidence == .exact)
        #expect(result.estimatedAccounts.isEmpty)
        #expect(result.formattedTotal == "$22.67")
    }

    @Test("混进一家估算，总体变 estimated，且 estimatedAccounts 里有它")
    func oneEstimatedProviderDowngradesTotal() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 11.05)]
                ),
                snapshot(
                    .neon,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 3.13)
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(roundedUSD: 14.18))
        #expect(result.confidence == .estimated)
        #expect(result.estimatedAccounts == [AccountID.fixture(for: .neon)])
        #expect(result.formattedTotal == "$14.18")
    }

    // MARK: - 预充值首月

    @Test("预充值首月没有月初快照，退化为接入以来的消耗，精度 partial")
    func prepaidWithoutMonthStartSnapshotIsPartial() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: date(2026, 8, 5, 9),
                    balanceUSD: Money(usd: 80)
                ),
                snapshot(
                    .openai,
                    kind: .prepaid,
                    fetchedAt: now,
                    balanceUSD: Money(usd: 42)
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 38))
        #expect(result.confidence == .partial)
        #expect(result.estimatedAccounts.isEmpty)
        #expect(result.formattedTotal == "$38.00")
    }

    // MARK: - 订阅扣款日

    @Test("订阅扣款日落在本月，计全额且不按天摊")
    func subscriptionChargeDayInMonthCountsInFull() {
        let now = date(2026, 8, 2, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 4),
                    period: .monthly,
                    anchorDate: date(2026, 3, 15),
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 4))
        #expect(result.confidence == .exact)
        // 2 号还没到扣款日，但规则是「落在本月」而不是「已经扣过」
        #expect(result.projectedMonthEndUSD == Money(usd: 4))
    }

    @Test("订阅扣款日 31 在 2 月钳到月末，计全额")
    func subscriptionChargeDayClampedWhenMonthTooShort() {
        let now = date(2026, 2, 15, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "年付保险",
                    amount: Money(usd: 31),
                    period: .monthly,
                    anchorDate: date(2026, 1, 31)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 31))
        #expect(result.projectedMonthEndUSD == Money(usd: 31))
    }

    @Test("扣款日 31：2 月非闰年与闰年都计全额", arguments: [2024, 2025])
    func subscriptionChargeDay31InFebruaryCountsInFull(year: Int) {
        let now = date(year, 2, 15, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "月末扣款",
                    amount: Money(usd: 31),
                    period: .monthly,
                    anchorDate: date(year, 1, 31)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 31))
        #expect(result.projectedMonthEndUSD == Money(usd: 31))
    }

    @Test("Snapshot 扣款日非法（≤0 或 >31）计 0", arguments: [0, -1, 32])
    func invalidChargeDayCountsZero(day: Int) {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .github,
                    kind: .subscription,
                    fetchedAt: now,
                    committedMonthlyUSD: Money(usd: 20),
                    chargeDayOfMonth: day
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.projectedMonthEndUSD == .zero)
    }

    // MARK: - 年付周年月

    @Test("年付，周年月计入全额")
    func annualSubscriptionCountsInFullInAnniversaryMonth() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "Claude Max",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2025, 8, 20)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 200))
        #expect(result.projectedMonthEndUSD == Money(usd: 200))
        #expect(result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == Money(usd: 200)
        })
    }

    @Test("年付，非周年月计 0")
    func annualSubscriptionCountsZeroOutsideAnniversaryMonth() {
        let now = date(2026, 7, 16, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "Claude Max",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2025, 8, 20)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.projectedMonthEndUSD == .zero)
        #expect(result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == .zero
        })
    }

    @Test("年付 1 月 31 日在 2 月不是周年月")
    func annualJanuary31IsNotAnniversaryInFebruary() {
        let now = date(2026, 2, 15, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "January annual",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2025, 1, 31)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.projectedMonthEndUSD == .zero)
    }

    @Test("年付 1 月 31 日在 1 月计入全额")
    func annualJanuary31CountsInJanuary() {
        let now = date(2026, 1, 15, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "January annual",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2025, 1, 31)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 200))
    }

    @Test("年付闰年 2 月 29 日，平年 2 月按 28 日计入")
    func annualFebruary29CountsOnFebruary28InCommonYear() {
        let now = date(2025, 2, 15, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "Leap day annual",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2024, 2, 29)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 200))
        #expect(result.projectedMonthEndUSD == Money(usd: 200))
    }

    // MARK: - 还没开始的订阅

    @Test("月付，anchorDate 在下个月：计 0")
    func monthlySubscriptionStartingNextMonthCountsZero() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 4),
                    period: .monthly,
                    anchorDate: date(2026, 9, 15),
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.projectedMonthEndUSD == .zero)
        #expect(result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == .zero
        })
    }

    @Test("月付，anchorDate 是本月 31 日、now 是本月 1 日：计全额")
    func monthlySubscriptionStartingLaterThisMonthCountsInFull() {
        // 账单口径：扣款日落在本月内就计全额。写成 now < anchorDate 会在这里漏掉。
        let now = date(2026, 8, 1)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 4),
                    period: .monthly,
                    anchorDate: date(2026, 8, 31),
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 4))
        #expect(result.projectedMonthEndUSD == Money(usd: 4))
    }

    @Test("年付，anchorDate 在明年同月：计 0")
    func annualSubscriptionStartingNextYearSameMonthCountsZero() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "Claude Max",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2027, 8, 20)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == .zero)
        #expect(result.projectedMonthEndUSD == .zero)
        #expect(result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == .zero
        })
    }

    @Test("年付，anchorDate 是往年同月：计全额")
    func annualSubscriptionFromPreviousYearSameMonthCountsInFull() {
        let now = date(2026, 8, 1)
        let result = compute(
            subscriptions: [
                MonthlySubscription(
                    name: "Claude Max",
                    amount: Money(usd: 200),
                    period: .annual,
                    anchorDate: date(2025, 8, 31)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 200))
        #expect(result.projectedMonthEndUSD == Money(usd: 200))
    }

    // MARK: - 手动订阅与 snapshot 撞车

    @Test("同一账号既有 subscription snapshot 又有手动订阅时，只计手动那笔")
    func manualSubscriptionSupersedesSnapshot() {
        let now = date(2026, 8, 16, 12)
        let account = AccountID.fixture(for: .github)
        let result = compute(
            snapshots: [
                snapshot(
                    .github,
                    accountID: account,
                    kind: .subscription,
                    fetchedAt: now,
                    committedMonthlyUSD: Money(usd: 4),
                    chargeDayOfMonth: 3
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 15),
                    accountID: account,
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 10))
        #expect(result.projectedMonthEndUSD == Money(usd: 10))
        #expect(result.facts.contains {
            $0.providerID == .github
                && $0.type == .subscriptionSuperseded
                && $0.kind == .subscription
                && $0.amountUSD == Money(usd: 4)
        })
        #expect(result.facts.contains {
            $0.providerID == .github
                && $0.type == .subscriptionIncluded
                && $0.amountUSD == Money(usd: 10)
        })
        #expect(!result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == Money(usd: 4)
        })
    }

    @Test("无主手动订阅不盖任何 API 订阅")
    func unaffiliatedManualSubscriptionDoesNotSupersede() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .github,
                    kind: .subscription,
                    fetchedAt: now,
                    committedMonthlyUSD: Money(usd: 4),
                    chargeDayOfMonth: 3
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 15),
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 14))
        #expect(!result.facts.contains { $0.type == .subscriptionSuperseded })
    }

    @Test("用量 snapshot 与手动订阅同时存在时两笔都计")
    func usageSnapshotDoesNotCollideWithManualSubscription() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 21.40)]
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "AWS Support",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 5),
                    providerID: .aws
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(roundedUSD: 31.40))
        #expect(!result.facts.contains { $0.type == .subscriptionSuperseded })
    }

    // MARK: - 跨月边界

    @Test("本月 1 号 00:00：用量为 0，订阅仍按本月扣款日全额计入")
    func monthStartMidnightExcludesTodayAndDoesNotProject() {
        let now = date(2026, 8, 1)
        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [
                        date(2026, 7, 31): Money(usd: 9),
                        date(2026, 8, 1): Money(usd: 10),
                    ]
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 4),
                    period: .monthly,
                    anchorDate: date(2026, 1, 3),
                    providerID: .github
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 4))
        #expect(result.projectedMonthEndUSD == Money(usd: 4))
    }

    @Test("月末最后一刻：本月日粒度全部计入，外推等于已花的用量加订阅")
    func monthEndLastInstantIncludesAllDays() {
        let now = date(2026, 8, 31, 23, 59, 59)
        var daily: [Date: Money] = [:]
        for day in 1...31 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 4),
                    period: .monthly,
                    anchorDate: date(2026, 1, 3)
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 35))
        #expect(result.projectedMonthEndUSD == Money(usd: 35))
    }

    // MARK: - 2 月与闰年

    @Test(arguments: [(2024, "$29.00"), (2025, "$28.00")])
    func projectionDenominatorUsesDaysInFebruary(year: Int, expectedProjection: String) {
        let now = date(year, 2, 15, 12)
        var daily: [Date: Money] = [:]
        for day in 1...15 {
            daily[date(year, 2, day)] = Money(usd: 1)
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(year, 2, 1),
                    periodEnd: date(year, 2, 28),
                    dailyUSD: daily
                )
            ],
            now: now
        )

        #expect(result.totalUSD == Money(usd: 15))
        #expect(result.projectedMonthEndUSD.formatted() == expectedProjection)
    }

    @Test("订阅不外推：预计月底只放大用量部分")
    func projectionDoesNotExtrapolateSubscriptions() {
        let now = date(2026, 8, 16, 12)
        var daily: [Date: Money] = [:]
        for day in 1...16 {
            daily[date(2026, 8, day)] = Money(usd: 1)
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: daily
                )
            ],
            subscriptions: [
                MonthlySubscription(
                    name: "GitHub Copilot",
                    amount: Money(usd: 10),
                    period: .monthly,
                    anchorDate: date(2026, 1, 3)
                )
            ],
            now: now
        )

        // 用量 16 / 16 × 31 = 31，订阅 10 不加码 → 41。若错误地连订阅一起外推会变成 50.375。
        #expect(result.totalUSD == Money(usd: 26))
        #expect(result.projectedMonthEndUSD == Money(usd: 41))
    }

    // MARK: - 单家失败

    @Test("单家取数失败且没有任何可用 Snapshot：不按 $0 计入，总数降为 partial")
    func missingUsableSnapshotDoesNotSilentlyShrinkAsExact() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 21.40)]
                ),
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31)
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(roundedUSD: 21.40))
        #expect(result.confidence == .partial)
        #expect(result.estimatedAccounts.isEmpty)
        #expect(result.formattedTotal == "$21.40")
        #expect(result.facts.contains {
            $0.providerID == .cloudflare && $0.type == .fetchFailed && $0.amountUSD == nil
        })
    }

    @Test("后来的失败 Snapshot 不能把上次成功金额悄悄抹成 0")
    func staleSuccessfulSnapshotKeepsLastAmount() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: date(2026, 8, 15, 8),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 11.05)]
                ),
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31)
                ),
            ],
            now: now
        )

        #expect(result.totalUSD == Money(roundedUSD: 11.05))
        #expect(result.confidence == .partial)
        #expect(result.formattedTotal == "$11.05")
    }

    // MARK: - kind 防双计

    @Test("同一条 snapshot 同时填余额和用量时，按 kind 只计一次")
    func mixedFieldsDoNotDoubleCount() {
        let now = date(2026, 8, 16, 12)
        let monthStartBalance = Money(usd: 100)
        let currentBalance = Money(usd: 42)
        let currentSpend = Money(usd: 80)

        func mixed(_ kind: ProviderKind, fetchedAt: Date, spend: Money, balance: Money) -> Snapshot {
            snapshot(
                .openai,
                kind: kind,
                fetchedAt: fetchedAt,
                periodStart: date(2026, 8, 1),
                periodEnd: date(2026, 8, 31),
                currentSpendUSD: spend,
                balanceUSD: balance
            )
        }

        let prepaid = compute(
            snapshots: [
                mixed(.prepaid, fetchedAt: date(2026, 7, 31, 23, 59), spend: Money(usd: 10), balance: monthStartBalance),
                mixed(.prepaid, fetchedAt: now, spend: currentSpend, balance: currentBalance),
            ],
            now: now
        )
        // 只认余额差 100 − 42 = 58；若把 80 也算进去会变成 138。
        #expect(prepaid.totalUSD == Money(usd: 58))
        #expect(prepaid.facts.contains {
            $0.type == .prepaidConsumption && $0.amountUSD == Money(usd: 58) && $0.kind == .prepaid
        })
        #expect(!prepaid.facts.contains { $0.type == .monthToDateUsage })

        let usage = compute(
            snapshots: [
                mixed(.usage, fetchedAt: date(2026, 7, 31, 23, 59), spend: Money(usd: 10), balance: monthStartBalance),
                mixed(.usage, fetchedAt: now, spend: currentSpend, balance: currentBalance),
            ],
            now: now
        )
        // 只认用量 80；若把余额差 58 也算进去会变成 138。
        #expect(usage.totalUSD == Money(usd: 80))
        #expect(usage.facts.contains {
            $0.type == .monthToDateUsage && $0.amountUSD == Money(usd: 80) && $0.kind == .usage
        })
        #expect(!usage.facts.contains { $0.type == .prepaidConsumption })
    }

    @Test("hasBillableMetrics 只认该 kind 该有的字段")
    func hasBillableMetricsFollowsKind() {
        let now = date(2026, 8, 16, 12)

        #expect(
            snapshot(
                .aws,
                kind: .usage,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 1),
                balanceUSD: Money(usd: 9)
            ).hasBillableMetrics
        )
        #expect(
            !snapshot(
                .aws,
                kind: .usage,
                fetchedAt: now,
                balanceUSD: Money(usd: 9)
            ).hasBillableMetrics
        )

        #expect(
            snapshot(
                .openai,
                kind: .prepaid,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 1),
                balanceUSD: Money(usd: 9)
            ).hasBillableMetrics
        )
        #expect(
            !snapshot(
                .openai,
                kind: .prepaid,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 1)
            ).hasBillableMetrics
        )

        #expect(
            snapshot(
                .github,
                kind: .subscription,
                fetchedAt: now,
                committedMonthlyUSD: Money(usd: 4),
                chargeDayOfMonth: 3
            ).hasBillableMetrics
        )
        #expect(
            !snapshot(
                .github,
                kind: .subscription,
                fetchedAt: now,
                chargeDayOfMonth: 3,
                freeQuotaUsedRatio: 0.5
            ).hasBillableMetrics
        )

        #expect(
            snapshot(
                .vercel,
                kind: .freeTier,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 5),
                freeQuotaUsedRatio: 0.34
            ).hasBillableMetrics
        )
        #expect(
            !snapshot(
                .vercel,
                kind: .freeTier,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 5)
            ).hasBillableMetrics
        )

        #expect(
            snapshot(
                .github,
                kind: .planAndUsage,
                fetchedAt: now,
                currentSpendUSD: Money(usd: 8),
                committedMonthlyUSD: Money(usd: 25)
            ).hasBillableMetrics
        )
        #expect(
            !snapshot(
                .github,
                kind: .planAndUsage,
                fetchedAt: now,
                balanceUSD: Money(usd: 9)
            ).hasBillableMetrics
        )
    }

    @Test("planAndUsage 月费全额计入、超额单独记一笔，不双计")
    func planAndUsageEmitsTwoFacts() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .github,
                    kind: .planAndUsage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 8),
                    committedMonthlyUSD: Money(usd: 25)
                )
            ],
            now: now
        )
        #expect(result.totalUSD == Money(usd: 33))
        #expect(result.variableUSD == Money(usd: 8))
        #expect(result.subscriptionUSD == Money(usd: 25))
        #expect(result.facts.contains {
            $0.type == .subscriptionIncluded && $0.amountUSD == Money(usd: 25)
        })
        #expect(result.facts.contains {
            $0.type == .monthToDateUsage && $0.amountUSD == Money(usd: 8)
        })
        #expect(result.projectedMonthEndUSD > Money(usd: 33))
    }

    @Test("Fact 是结构化字段：取数失败带类型枚举，不带金额也不带句子")
    func fetchFailedFactIsStructuredNotASentence() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .cloudflare,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31)
                )
            ],
            now: now
        )

        #expect(result.facts.count == 1)
        let fact = result.facts[0]
        #expect(fact.providerID == .cloudflare)
        #expect(fact.kind == .usage)
        #expect(fact.type == .fetchFailed)
        #expect(fact.amountUSD == nil)
        #expect(fact.comparisonUSD == nil)
        #expect(fact.changeRatio == nil)
        #expect(fact.freeQuotaUsedRatio == nil)
        #expect(fact.confidence == .partial)
        #expect(result.totalUSD == .zero)
        #expect(result.confidence == .partial)
    }

    // MARK: - 上月同期

    @Test("3 月 31 日对比上月同期：2 月没有 31 日，用量算到 2 月最后一天")
    func comparisonClampsWhenPreviousMonthIsShorter() throws {
        let now = date(2026, 3, 31, 12)
        var march: [Date: Money] = [:]
        for day in 1...31 {
            march[date(2026, 3, day)] = Money(usd: 2)
        }
        var february: [Date: Money] = [:]
        for day in 1...28 {
            february[date(2026, 2, day)] = Money(usd: 1)
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 2, 28, 12),
                    periodStart: date(2026, 2, 1),
                    periodEnd: date(2026, 2, 28),
                    dailyUSD: february
                ),
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 3, 1),
                    periodEnd: date(2026, 3, 31),
                    dailyUSD: march
                ),
            ],
            now: now
        )

        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.amountUSD == Money(usd: 62))
        #expect(fact.comparisonUSD == Money(usd: 28))
        #expect(result.comparisonUSD == Money(usd: 28))
        #expect(result.comparisonWindow?.dayOfMonth == 28)
    }

    @Test("上月同期是 0 时 changeRatio 为 nil，不是 +∞ 也不是 100%")
    func changeRatioIsNilWhenComparisonIsZero() throws {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 7, 16, 12),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 16),
                    currentSpendUSD: Money.zero
                ),
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 21.40)]
                ),
            ],
            now: now
        )

        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.comparisonUSD == .zero)
        #expect(fact.changeRatio == nil)
        #expect(result.changeRatio == nil)
    }

    @Test("两家从量一家缺同期，本月合计含缺的那家，上月只含能比的")
    func overallComparisonUsesOverlappingSet() throws {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 7, 16, 12),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 16),
                    currentSpendUSD: Money(usd: 10)
                ),
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 20)
                ),
                snapshot(
                    .neon,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 10)
                ),
            ],
            now: now
        )
        let aws = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        let neon = try #require(result.facts.first { $0.providerID == .neon && $0.type == .monthToDateUsage })
        #expect(aws.comparisonUSD == Money(usd: 10))
        #expect(neon.comparisonUSD == nil)
        #expect(result.comparisonUSD == Money(usd: 10))
        #expect(result.changeRatio == 2)
    }

    @Test("没有上月读数时 comparisonUSD 是 nil，不是 $0")
    func missingLastMonthDataLeavesComparisonNil() throws {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    dailyUSD: [date(2026, 8, 1): Money(roundedUSD: 21.40)]
                )
            ],
            now: now
        )

        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.comparisonUSD == nil)
        #expect(fact.changeRatio == nil)
        #expect(result.comparisonUSD == nil)
        #expect(result.changeRatio == nil)
    }

    @Test("AWS 本月 $21.40、上月同期 $13.20 → +62%")
    func awsSamePeriodLastMonthIsSixtyTwoPercent() throws {
        let now = date(2026, 8, 16, 12)
        var august: [Date: Money] = [:]
        for day in 1...16 {
            august[date(2026, 8, day)] = Money(usd: day <= 8 ? 0.5 : (day == 16 ? 2.0 : 2.2))
        }

        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 7, 16, 12),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 16),
                    currentSpendUSD: Money(roundedUSD: 13.20)
                ),
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(roundedUSD: 21.40),
                    dailyUSD: august
                ),
            ],
            now: now
        )

        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.amountUSD == Money(roundedUSD: 21.40))
        #expect(fact.comparisonUSD == Money(roundedUSD: 13.20))
        let ratio = try #require(fact.changeRatio)
        #expect(Int((ratio * 100).rounded()) == 62)
    }

    @Test("上月整月发票本月才刷到：筛选上月有数，本月同期按天数切开，不是空白")
    func lastMonthInvoiceFetchedThisMonthStillCompares() throws {
        let now = date(2026, 8, 16, 12)
        let julyInvoice = snapshot(
            .aws,
            kind: .usage,
            fetchedAt: date(2026, 8, 2, 9),
            periodStart: date(2026, 7, 1),
            periodEnd: date(2026, 7, 31),
            currentSpendUSD: Money(usd: 31)
        )
        let august = snapshot(
            .aws,
            kind: .usage,
            fetchedAt: now,
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            currentSpendUSD: Money(usd: 16)
        )

        let july = MonthToDateCalculator.compute(
            snapshots: [julyInvoice, august],
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(monthsBack: 1)
        )
        #expect(july.variableUSD == Money(usd: 31))

        let current = compute(snapshots: [julyInvoice, august], now: now)
        let fact = try #require(current.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.amountUSD == Money(usd: 16))
        #expect(fact.comparisonUSD == Money(usd: 16))
        #expect(current.comparisonUSD == Money(usd: 16))
    }

    @Test("同一天多次刷新，上月同期按后取覆盖，不把日费用加总")
    func repeatedRefreshDoesNotMultiplyComparisonDaily() throws {
        let now = date(2026, 8, 16, 12)
        var july: [Date: Money] = [:]
        for day in 1...16 {
            july[date(2026, 7, day)] = Money(usd: 2)
        }
        var snapshots: [Snapshot] = []
        for hour in 0..<8 {
            snapshots.append(
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 7, 16, hour),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    dailyUSD: july
                )
            )
        }
        snapshots.append(
            snapshot(
                .aws,
                kind: .usage,
                fetchedAt: now,
                periodStart: date(2026, 8, 1),
                periodEnd: date(2026, 8, 31),
                dailyUSD: [date(2026, 8, 1): Money(usd: 1)]
            )
        )
        let result = compute(snapshots: snapshots, now: now)
        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.comparisonUSD == Money(usd: 32))
        #expect(fact.amountUSD == Money(usd: 1))
    }

    @Test("回看上月时，再往前一个月没数仍不能对比")
    func lookingAtLastMonthStillNeedsTheMonthBefore() {
        let now = date(2026, 8, 16, 12)
        let july = MonthToDateCalculator.compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: date(2026, 8, 2, 9),
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(usd: 31)
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(monthsBack: 1)
        )
        #expect(july.variableUSD == Money(usd: 31))
        #expect(july.comparisonUSD == nil)
    }

    @Test("本月累计账期跨上月，不能当成上月同期")
    func currentMonthCumulativeMustNotCountAsLastMonth() throws {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                snapshot(
                    .aws,
                    kind: .usage,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 17),
                    periodEnd: date(2026, 8, 16),
                    currentSpendUSD: Money(usd: 50)
                )
            ],
            now: now
        )
        let fact = try #require(result.facts.first { $0.providerID == .aws && $0.type == .monthToDateUsage })
        #expect(fact.comparisonUSD == nil)
        #expect(result.comparisonUSD == nil)
    }

    // MARK: - 固定时钟

    private func compute(
        snapshots: [Snapshot] = [],
        subscriptions: [MonthlySubscription] = [],
        now: Date
    ) -> MonthToDate {
        MonthToDateCalculator.compute(
            snapshots: snapshots,
            subscriptions: subscriptions,
            now: now,
            calendar: calendar
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        _ second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components)!
    }

    @Test("同厂商两个预充值账号的月初余额绝不串组")
    func twoPrepaidAccountsOfSameVendorDoNotShareHistory() {
        let now = date(2026, 8, 16, 12)
        let work = AccountID.fixture(1)
        let personal = AccountID.fixture(2)
        let result = compute(
            snapshots: [
                snapshot(
                    .openai,
                    accountID: work,
                    kind: .prepaid,
                    fetchedAt: date(2026, 7, 31, 23, 59),
                    balanceUSD: Money(usd: 100)
                ),
                snapshot(
                    .openai,
                    accountID: work,
                    kind: .prepaid,
                    fetchedAt: now,
                    balanceUSD: Money(usd: 40)
                ),
                snapshot(
                    .openai,
                    accountID: personal,
                    kind: .prepaid,
                    fetchedAt: date(2026, 7, 31, 23, 59),
                    balanceUSD: Money(usd: 20)
                ),
                snapshot(
                    .openai,
                    accountID: personal,
                    kind: .prepaid,
                    fetchedAt: now,
                    balanceUSD: Money(usd: 10)
                ),
            ],
            now: now
        )
        #expect(result.totalUSD == Money(usd: 70))
        #expect(result.facts.filter { $0.type == .prepaidConsumption }.count == 2)
    }

    @Test("上月手填不算进本月")
    func lastMonthManualUsageDoesNotCount() {
        let now = date(2026, 9, 5, 12)
        let result = compute(
            snapshots: [
                Snapshot(
                    providerID: .fly,
                    accountID: AccountID.fixture(for: .fly),
                    kind: .usage,
                    source: .manual,
                    fetchedAt: date(2026, 8, 20),
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 40)
                )
            ],
            now: now
        )
        #expect(result.totalUSD == .zero)
        #expect(result.confidence == .partial)
    }

    @Test("事后补填上月不算进本月")
    func backfilledLastMonthDoesNotCountThisMonth() {
        let now = date(2026, 8, 20, 12)
        let result = compute(
            snapshots: [
                Snapshot(
                    providerID: .fly,
                    accountID: AccountID.fixture(for: .fly),
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(usd: 40)
                )
            ],
            now: now
        )
        #expect(result.totalUSD == .zero)
        #expect(result.confidence == .partial)
    }

    @Test("回看过去某月时，事后补填的手填计入那个月")
    func backfilledManualUsageCountsInThatMonth() {
        let now = date(2026, 8, 20, 12)
        let result = MonthToDateCalculator.compute(
            snapshots: [
                Snapshot(
                    providerID: .fly,
                    accountID: AccountID.fixture(for: .fly),
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 7, 1),
                    periodEnd: date(2026, 7, 31),
                    currentSpendUSD: Money(usd: 40)
                )
            ],
            subscriptions: [],
            now: now,
            calendar: calendar,
            filter: DashboardFilter(monthsBack: 1)
        )
        #expect(result.totalUSD == Money(usd: 40))
    }

    @Test("当月手填计入用量，周期累计仍是估算")
    func thisMonthManualUsageCounts() {
        let now = date(2026, 8, 16, 12)
        let result = compute(
            snapshots: [
                Snapshot(
                    providerID: .fly,
                    accountID: AccountID.fixture(for: .fly),
                    kind: .usage,
                    source: .manual,
                    fetchedAt: now,
                    periodStart: date(2026, 8, 1),
                    periodEnd: date(2026, 8, 31),
                    currentSpendUSD: Money(usd: 40)
                )
            ],
            now: now
        )
        #expect(result.totalUSD == Money(usd: 40))
        #expect(result.confidence == .estimated)
    }

    @Test("空着的非美元钱包不把整家标成估算")
    func emptyConvertedWalletIsNotEstimated() {
        let snapshot = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .prepaid,
            fetchedAt: date(2026, 8, 16, 12),
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            balanceUSD: Money(usd: Decimal(string: "8.5")!),
            wallets: [
                ConvertedAmount(currency: "CNY", amount: 0, usdPerUnit: Decimal(string: "0.1404")!, usd: 0),
                ConvertedAmount(
                    currency: "USD",
                    amount: Decimal(string: "8.5")!,
                    usdPerUnit: 1,
                    usd: Decimal(string: "8.5")!
                ),
            ]
        )
        #expect(!snapshot.isCurrencyConverted)
    }

    @Test("有余额的非美元钱包才标估算")
    func fundedConvertedWalletIsEstimated() {
        let cny = ConvertedAmount(
            currency: "CNY",
            amount: Decimal(string: "14.17")!,
            usdPerUnit: Decimal(string: "0.1404")!,
            usd: Decimal(string: "1.99")!
        )
        let snapshot = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .prepaid,
            fetchedAt: date(2026, 8, 16, 12),
            periodStart: date(2026, 8, 1),
            periodEnd: date(2026, 8, 31),
            balanceUSD: Money(usd: Decimal(string: "1.99")!),
            converted: cny,
            wallets: [
                cny,
                ConvertedAmount(currency: "USD", amount: 0, usdPerUnit: 1, usd: 0),
            ]
        )
        #expect(snapshot.isCurrencyConverted)
    }

    private func snapshot(
        _ provider: ProviderID,
        accountID: AccountID? = nil,
        kind: ProviderKind,
        fetchedAt: Date,
        periodStart: Date? = nil,
        periodEnd: Date? = nil,
        currentSpendUSD: Money? = nil,
        balanceUSD: Money? = nil,
        committedMonthlyUSD: Money? = nil,
        chargeDayOfMonth: Int? = nil,
        freeQuotaUsedRatio: Double? = nil,
        dailyUSD: [Date: Money]? = nil
    ) -> Snapshot {
        Snapshot(
            providerID: provider,
            accountID: accountID ?? AccountID.fixture(for: provider),
            kind: kind,
            fetchedAt: fetchedAt,
            periodStart: periodStart ?? fetchedAt,
            periodEnd: periodEnd ?? fetchedAt,
            currentSpendUSD: currentSpendUSD,
            balanceUSD: balanceUSD,
            committedMonthlyUSD: committedMonthlyUSD,
            chargeDayOfMonth: chargeDayOfMonth,
            freeQuotaUsedRatio: freeQuotaUsedRatio,
            dailyUSD: dailyUSD
        )
    }
}
