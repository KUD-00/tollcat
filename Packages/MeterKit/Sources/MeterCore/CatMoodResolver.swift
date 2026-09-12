import Foundation

/// 用已经算好的本月合计决定猫的表情。阈值写在这里，UI 不许另写一套。
///
/// 优先级从上到下，第一条命中就停：
/// 1. `dead`：合计相对上月同期涨了 **100% 以上**（`changeRatio > 1`）。
///    翻倍已经不是「这个月有点贵」，是用量或单价发生了结构性变化。
///    正好 100% 仍归 `shocked`，避免一条线同时落进两档。
/// 2. `shocked`：涨幅 **50%…100%**（含两端）。50% 和仪表「涨得反常」是同一条线，
///    但这里看的是**合计**；单家 50% 只够 `alert`。
/// 3. `alert`：有余额告急，或有异常项。
/// 4. `sleeping`：还没接入任何 provider，或这次没有任何可读账单。
/// 5. `awkward`：有 provider 取数失败，屏幕上是陈旧数据。
/// 6. `saved`：比上月同期少，或全部落在免费额度里、没有应付金额。
/// 7. `normal`：其余。
public enum CatMoodResolver: Sendable {
    /// 严格大于 100%。正好翻倍还没到「把猫送走」。
    public static let deadChangeRatio: Double = 1.0

    /// 含 50%。异常卡（看单家）和猫表情（看合计）共用这一条分界。
    ///
    /// 用量账单常有 10–30% 的工作日 / 发布波动；50% 是「多半多开了什么」的分界，
    /// 也正好只留下设计稿里那张 AWS +62%。
    public static let shockedChangeRatio: Double = 0.5

    public static func mood(
        for monthToDate: MonthToDate?,
        hasAnyProvider: Bool,
        hasAnyReadableData: Bool,
        hasBalanceAlert: Bool,
        hasAnomaly: Bool,
        hasStaleData: Bool
    ) -> CatMood {
        if let ratio = monthToDate?.changeRatio {
            if ratio > deadChangeRatio {
                return .dead
            }
            if ratio >= shockedChangeRatio {
                return .shocked
            }
        }

        if hasBalanceAlert || hasAnomaly {
            return .alert
        }

        if !hasAnyProvider || !hasAnyReadableData || monthToDate == nil {
            return .sleeping
        }

        if hasStaleData {
            return .awkward
        }

        if let monthToDate {
            if let ratio = monthToDate.changeRatio, ratio < 0 {
                return .saved
            }
            if isEntirelyWithinFreeQuota(monthToDate) {
                return .saved
            }
        }

        return .normal
    }

    /// 有计入合计的用量 / 预充值消耗 / 订阅 / 免费额度，才算「读到了数据」。
    public static func hasReadableData(in monthToDate: MonthToDate) -> Bool {
        monthToDate.facts.contains { fact in
            switch fact.type {
            case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded, .freeQuota:
                return true
            case .subscriptionSuperseded, .fetchFailed:
                return false
            }
        }
    }

    /// 单家环比达到惊吓线，才算异常项。合计的惊吓由 `mood` 自己判。
    public static func hasAnomaly(in monthToDate: MonthToDate) -> Bool {
        monthToDate.facts.contains { fact in
            guard let ratio = fact.changeRatio, ratio >= shockedChangeRatio else {
                return false
            }
            switch fact.type {
            case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
                return true
            case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                return false
            }
        }
    }

    /// 还能撑过这么多天就不算告急。和仪表余额卡同一条 30 天线。
    public static let prepaidAlertDays: Int = 30

    public static func hasBalanceAlert(
        in runways: [PrepaidRunway],
        daysRemaining: Int = prepaidAlertDays
    ) -> Bool {
        runways.contains { $0.daysRemaining <= daysRemaining }
    }

    private static func isEntirelyWithinFreeQuota(_ monthToDate: MonthToDate) -> Bool {
        let billed = monthToDate.facts.contains { fact in
            switch fact.type {
            case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
                return (fact.amountUSD ?? .zero) > .zero
            case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                return false
            }
        }
        let free = monthToDate.facts.contains { $0.type == .freeQuota }
        return !billed && free
    }
}
