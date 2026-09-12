import Foundation
import MeterCore
import MeterFormat

/// 取景框的人话版本。**首屏、筛选面板、分享卡共用这一处**。
///
/// 为什么非要收在一个地方：筛选过的数字不是「本月账单」，说明它的那句话
/// 就是它的一部分。三处各写一份，早晚会有一处漏一维——那时候屏幕上或者
/// 别人手机里就会出现一个没有限定语的数字，而它看起来完全正常。
///
/// 所有入口都收 `asOf`（**已经过 `filter.anchor` 折算的那个时间点**，也就是
/// 窗口的最后一瞬），不收原始的 `now`。参数名写死这一点是有原因的：一开始这里
/// 收 `now` 并在内部自己 anchor，调用方传的却已经是锚点，于是「七月」被算成了
/// 「六月」。让类型说不出「我要哪一个」的时候，就用名字说。
///
/// `window` 同理必须从外面传：`.allTime` / `.yearToDate` 有多长要看数据和日历，
/// 这里再解析一遍就等于把那份逻辑抄了第二份。
public enum DashboardFilterSummary {
    /// 名单里最多点几个名字，再多改成报个数。
    public static let maxNamedProviders = 2

    /// 短标题：「本月」/「七月」/「近 3 个月」/「五月–七月」/「今年至今」/「有数据以来」。
    /// 给 chip、页面标题、分享卡用——那几处放不下补充说明。
    ///
    /// 收 `period` 而不是整份取景框：标题只由时间那一维决定，排除了谁不进标题
    /// （那是 `scopeNote` 的事）。少收一个参数，也就少一处能传错的东西。
    public static func periodTitle(
        period: DashboardPeriod,
        window: MonthWindow,
        asOf: Date,
        calendar: Calendar
    ) -> String {
        switch period {
        case .yearToDate:
            return String(localized: L("今年至今"))
        case .allTime:
            return String(localized: L("有数据以来"))
        case let .months(back, _):
            if window.isSingleMonth {
                return back == 0
                    ? String(localized: L("本月"))
                    : MeterDateFormat.monthName(now: asOf, calendar: calendar)
            }
            if back == 0 {
                return String(localized: L("近 \(window.monthCount) 个月"))
            }
            return MeterDateFormat.monthRange(
                from: windowStart(asOf: asOf, window: window, calendar: calendar),
                to: asOf,
                calendar: calendar
            )
        }
    }

    /// 页面标题和分享卡上的期间名。
    ///
    /// 和 `periodTitle` 只差一处：**单个整月一律写月份名，不写「本月」。**
    /// 这两处的字都会被晚一点再看到——导航标题跟着页面滚、分享卡直接发到别人
    /// 手机上——那时候「本月」是哪个月已经没人说得准了。多月区间没有这个问题，
    /// 「近 3 个月」自己就带着相对性，写成月份范围反而更难读。
    public static func periodHeading(
        period: DashboardPeriod,
        window: MonthWindow,
        asOf: Date,
        calendar: Calendar
    ) -> String {
        if case .months = period, window.isSingleMonth {
            return MeterDateFormat.monthName(now: asOf, calendar: calendar)
        }
        return periodTitle(period: period, window: window, asOf: asOf, calendar: calendar)
    }

    /// 「之最」的节标题。当月仍是「本月之最」；别的区间把期间名接上去。
    public static func superlativesTitle(
        period: DashboardPeriod,
        window: MonthWindow,
        asOf: Date,
        calendar: Calendar
    ) -> String {
        if period.isCurrentMonth {
            return String(localized: L("本月之最"))
        }
        let title = periodTitle(period: period, window: window, asOf: asOf, calendar: calendar)
        return String(localized: L("\(title)之最"))
    }

    /// 限定语里的时间那一段。比 `periodTitle` 多一句补充。
    ///
    /// 「有数据以来」必须写出**从哪个月起**。数据只从接入那天开始，不写清楚的话，
    /// 那个数字会被当成「我这辈子在云上花的钱」——那是这个 App 最不该造成的误解。
    private static func periodNote(
        filter: DashboardFilter,
        window: MonthWindow,
        asOf: Date,
        calendar: Calendar
    ) -> String {
        let title = periodTitle(period: filter.period, window: window, asOf: asOf, calendar: calendar)
        guard case .allTime = filter.period else { return title }
        let start = windowStart(asOf: asOf, window: window, calendar: calendar)
        let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: asOf)
        let startName = sameYear
            ? MeterDateFormat.monthName(now: start, calendar: calendar)
            : MeterDateFormat.yearMonth(start, calendar: calendar)
        return String(localized: L("\(title)（自\(startName)起）"))
    }

    /// 时间之外的排除名单：「排除 AWS」。没排过就是 nil。
    ///
    /// 订阅口径**不在这儿**：它由大数字旁的切换自己说明，算进时日期上面
    /// 那行括号是金额分解，写进限定语等于同一句话说两遍。
    public static func scopeNote(
        filter: DashboardFilter,
        connections: [ProviderConnectionState]
    ) -> String? {
        excludedNote(filter.excludedAccounts, connections: connections)
    }

    /// 完整一行：「七月 · 排除 AWS」。什么都没筛就是 nil。
    ///
    /// 时间那一段只有在**不是本月**时才写进去。本月是默认视角，
    /// 给它加一句「本月」等于给所有人加一句废话，反而让真正的限定语变钝。
    public static func full(
        filter: DashboardFilter,
        window: MonthWindow,
        asOf: Date,
        calendar: Calendar,
        connections: [ProviderConnectionState] = []
    ) -> String? {
        guard filter.isActive else { return nil }
        var parts: [String] = []
        if !filter.isCurrentMonth {
            parts.append(periodNote(filter: filter, window: window, asOf: asOf, calendar: calendar))
        }
        if let scope = scopeNote(filter: filter, connections: connections) {
            parts.append(scope)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// 窗口第一天所在月的月首。`asOf` 落在窗口最新的那个月里，往前退 count-1 个月即可。
    private static func windowStart(
        asOf: Date,
        window: MonthWindow,
        calendar: Calendar
    ) -> Date {
        guard
            let newestStart = calendar.date(from: calendar.dateComponents([.year, .month], from: asOf)),
            let start = calendar.date(byAdding: .month, value: -(window.monthCount - 1), to: newestStart)
        else {
            return asOf
        }
        return start
    }

    /// 该厂商账号全部被排除时写「排除 Cloudflare」；只排除其中一份写账号标题。
    /// 超过 `maxNamedProviders` 报个数，用「个账号」不是「家」。
    private static func excludedNote(
        _ ids: Set<AccountID>,
        connections: [ProviderConnectionState]
    ) -> String? {
        guard !ids.isEmpty else { return nil }
        let names = displayNames(ids, connections: connections)
        if names.isEmpty {
            return String(localized: L("排除 \(ids.count) 个账号"))
        }
        if names.count <= maxNamedProviders {
            return String(localized: L("排除 \(names.joined(separator: "、"))"))
        }
        return String(localized: L("排除 \(names.count) 个账号"))
    }

    /// 排序后再取名字：同一份筛选每次都得到同一句话。
    public static func displayNames(
        _ ids: Set<AccountID>,
        connections: [ProviderConnectionState]
    ) -> [String] {
        let enabled = connections.filter(\.isEnabled)
        let byProvider = Dictionary(grouping: enabled, by: \.providerID)
        let excluded = enabled.filter { ids.contains($0.accountID) }
        let excludedByProvider = Dictionary(grouping: excluded, by: \.providerID)

        var names: [String] = []
        for (providerID, accounts) in excludedByProvider {
            let vendorName = ProviderIdentity.known(providerID)?.displayName
                ?? providerID.rawValue
            let allOfVendor = byProvider[providerID] ?? []
            let allExcluded = !allOfVendor.isEmpty
                && allOfVendor.allSatisfy { ids.contains($0.accountID) }
            if allExcluded {
                names.append(vendorName)
            } else {
                for account in accounts {
                    names.append(
                        AccountTitle.context(
                            for: account.accountID,
                            connections: enabled,
                            providerDisplayName: vendorName
                        ).visual
                    )
                }
            }
        }

        return names.sorted()
    }
}
