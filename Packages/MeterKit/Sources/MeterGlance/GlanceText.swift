import Foundation

/// 表盘和手表 App 上所有固定的字。金额和「预计月底」那种带数的句子是 iPhone 排好送来的，
/// 这里只剩手表自己要说的：标题、空态、以及「几小时前」——这句必须在手表上现算，
/// 因为时间一直在走，而 iPhone 不一定醒着。
public enum GlanceText {
    public static var monthTitle: LocalizedStringResource { L("本月") }
    public static var budgetTitle: LocalizedStringResource { L("预算") }
    public static var servicesTitle: LocalizedStringResource { L("服务") }
    public static var sublinesTitle: LocalizedStringResource { L("花在哪了") }
    public static var last30Days: LocalizedStringResource { L("近 30 天") }

    public static var noBills: LocalizedStringResource { L("还没有账单") }
    public static var noBillsHint: LocalizedStringResource { L("在 iPhone 上添加服务") }
    public static var waitingForMonth: LocalizedStringResource { L("等 iPhone 更新本月的数") }
    public static var neverSynced: LocalizedStringResource { L("打开 iPhone 上的 TollCat") }
    public static var neverSyncedDetail: LocalizedStringResource {
        L("手表上的数都来自 iPhone。在 iPhone 上打开一次 TollCat，这里就有了。")
    }
    public static var noBudget: LocalizedStringResource { L("没设预算") }

    /// 行内那一格：「本月 $47.20」。
    public static func monthInline(_ amount: String) -> LocalizedStringResource {
        L("本月 \(amount)")
    }

    /// 「3小时前更新」。数据旧了才上屏。
    public static func updated(_ date: Date, now: Date) -> LocalizedStringResource {
        L("\(relative(date, now: now))更新")
    }

    /// 手表 App 最底下那一行：这些数从哪来、有多新。
    public static func synced(_ date: Date?, now: Date) -> LocalizedStringResource? {
        guard let date else { return nil }
        if now.timeIntervalSince(date) < 60 {
            return L("刚从 iPhone 同步")
        }
        return L("\(relative(date, now: now))从 iPhone 同步")
    }

    static func relative(_ date: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        // 两台设备的钟差几秒，「1 分钟后更新」是一句不可能的话。
        return formatter.localizedString(for: min(date, now), relativeTo: now)
    }

    public static func spokenMonth(_ month: GlanceMonth) -> String {
        var parts = [String(localized: monthTitle), month.spokenAmount]
        if let projection = month.spokenProjection { parts.append(projection) }
        if let budget = month.budget { parts.append(budget.spokenLabel) }
        return parts.joined(separator: "，")
    }
}
