import Foundation

/// 仪表独有的两条「显不显示」分界。写在这里是因为它们是产品判断，不是视觉 token。
/// 异常卡和余额卡的分界与猫表情是同一条产品线，直接读
/// `CatMoodResolver.shockedChangeRatio` / `prepaidAlertDays`，不留第二份名字。
public enum DashboardModuleThresholds {
    /// 额度用过 80% 才叫「快超了」。fixture 把 Vercel 调到 80% 以上，卡才会出现。
    public static let freeQuotaUsedRatio: Double = 0.80

    /// SPEC 第 05 节：未来 7 天要扣的订阅。
    public static let upcomingChargeDays: Int = 7

    /// 「即将扣款」暂时下架。
    ///
    /// 这块要说「几天后扣一笔」，可它的两个来源都到不了日：手动订阅只记月份
    /// （`MonthlySubscription` 拿 anchorDate 当扣款日，用户填不了准确的那天），
    /// API 那边的 `chargeDayOfMonth` 只有少数几家报。数据跟不上，报出来的日期
    /// 就是编的——先关掉，等订阅能记到日再打开这一处。
    ///
    /// 五个壳读的都是这一个开关：iOS / Mac 经 `DashboardModuleID.isRetired`
    /// （模块不进仪表盘、也不进编辑面），Android / Windows 经 `ProductDashboard`
    /// 那一行（JNI 直接给空数组）。别在别处再判一次。
    public static let showsUpcomingCharges = false
}
