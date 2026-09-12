import Foundation
import Observation
import MeterCore
import MeterProviders
import MeterModules

/// 筛选面板的状态。
///
/// **面板上改的是一份草稿,按底栏「用这个」才落到仪表盘。**
///
/// 为什么不做实时生效：两维一起调的时候，中间态往往是没意义的组合
/// （先翻月份、再排服务），每一步都重算一次会让背后的数字跳两下，
/// 而用户其实只关心终态。关掉抽屉（系统 X 或下滑）等于丢掉草稿。
///
/// 订阅口径不在这份草稿的可编辑面上——那颗切换在首屏大数字旁边，即改即生效。
/// 草稿仍然原样带着它（`draft` 从 `dashboard.filter` 整份拷），所以按「用这个」
/// 不会把首屏切好的口径顶回去。
///
/// 代价是要在面板里自己算一遍预览值——那不是冗余，是这个设计的正价值：
/// 用户在按下之前就能看见筛完是多少。
@MainActor
@Observable
final class DashboardFilterModel {
    private(set) var draft: DashboardFilter

    private let dashboard: DashboardModel

    init(dashboard: DashboardModel) {
        self.dashboard = dashboard
        self.draft = dashboard.filter
    }

    // MARK: - 编辑草稿

    var period: DashboardPeriod {
        get { draft.period }
        set { draft.period = newValue.normalized }
    }

    func select(_ period: DashboardPeriod) {
        self.period = period
    }

    func isSelected(_ period: DashboardPeriod) -> Bool {
        draft.period == period.normalized
    }

    var monthsBack: Int {
        get { draft.monthsBack }
        set { draft.monthsBack = min(max(newValue, 0), DashboardFilter.maxMonthsBack) }
    }

    func isIncluded(_ id: AccountID) -> Bool {
        draft.includes(id)
    }

    func setIncluded(_ isIncluded: Bool, for id: AccountID) {
        draft = isIncluded ? draft.including(id) : draft.excluding(id)
    }

    func includeAllProviders() {
        draft.excludedAccounts = []
    }

    /// 全部排掉之后总数必然是 0,那不是任何人想要的视角,所以不提供「全不选」。
    /// 只提供「只看这一份」——用一次点击表达「其他都不看」。
    func onlyAccount(_ id: AccountID) {
        draft.excludedAccounts = Set(availableAccounts.map(\.id)).subtracting([id])
    }

    var isDraftActive: Bool { draft.isActive }
    var hasUnappliedChanges: Bool { draft != dashboard.filter }

    /// 面板上的时间控件跟仪表盘同一个时钟走（开发层的「时间覆盖」也在这条上）。
    var calendar: Calendar { dashboard.clock.calendar }
    var now: Date { dashboard.clock.now }

    // MARK: - 可选项

    struct MonthOption: Identifiable, Hashable {
        var monthsBack: Int
        var title: String
        var id: Int { monthsBack }
    }

    struct SpanOption: Identifiable, Hashable {
        var period: DashboardPeriod
        var title: String
        var id: String
    }

    struct AccountOption: Identifiable, Hashable {
        var id: AccountID
        var providerID: ProviderID
        var displayName: String
        var colorKey: String
        var siblingCount: Int
        var vendorDisplayName: String
    }

    /// 只列**真的有读数的那几个月**，不摆 12 个空月份。
    ///
    /// 本月永远在（就算还没刷过，那也是用户此刻想看的东西）。往前的月份
    /// 要么有快照落在那个月里，要么有一笔订阅算得进那个月——两者都没有的
    /// 月份点进去只会看到 $0，而 $0 和「没数据」在这个 App 里是两件事。
    var monthOptions: [MonthOption] {
        let calendar = dashboard.clock.calendar
        let now = dashboard.clock.now
        return availableMonthsBack.map { back in
            let filter = DashboardFilter(monthsBack: back)
            return MonthOption(
                monthsBack: back,
                title: DashboardFilterSummary.periodTitle(
                    period: filter.period,
                    window: MonthWindow(newestBack: back, oldestBack: back),
                    asOf: filter.anchor(now: now, calendar: calendar),
                    calendar: calendar
                )
            )
        }
    }

    /// 跨月的几档。和上面那行月份**语义不重叠**：一行回答「哪个月」，
    /// 这一行回答「多长一段」，所以选中永远只落在其中一行，不会两颗同时亮。
    ///
    /// 同样只列撑得住的档：手上只有两个月读数时不出「近 6 个月」——
    /// 那一档点进去只是把同样的数换个说法，还顺带暗示「你有半年数据」。
    var spanOptions: [SpanOption] {
        let deepest = availableMonthsBack.max() ?? 0
        guard deepest >= 1 else { return [] }
        var options: [SpanOption] = []
        for count in [3, 6] where deepest >= count - 1 {
            options.append(
                SpanOption(
                    period: .months(back: 0, count: count),
                    title: String(localized: L("近 \(count) 个月")),
                    id: "recent-\(count)"
                )
            )
        }
        let month = dashboard.clock.calendar.component(.month, from: dashboard.clock.now)
        if month > 1 {
            options.append(
                SpanOption(
                    period: .yearToDate,
                    title: String(localized: L("今年至今")),
                    id: "ytd"
                )
            )
        }
        options.append(
            SpanOption(
                period: .allTime,
                title: String(localized: L("全期间")),
                id: "all"
            )
        )
        return options
    }

    /// 手里真的有数的那几个月，从近到远。
    ///
    /// 读账本的 `hasReading`，不扫快照。「这个月有没有读数」这条判断以前在这里
    /// 又写了一遍（日粒度按日归属、周期累计按账期是否压到这个月），和折叠里那一份
    /// 迟早会分家——而分家的表现是「面板上列出来的月份，点进去是空的」。
    private var availableMonthsBack: [Int] {
        let calendar = dashboard.clock.calendar
        let now = dashboard.clock.now
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return [0]
        }
        let withReadings = Set(dashboard.ledger.rollups.filter(\.hasReading).map(\.monthStart))
        return (0...DashboardPeriod.maxMonthsBack).filter { back in
            // 本月永远在：就算还没刷过，那也是用户此刻想看的东西。
            guard back > 0 else { return true }
            guard
                let monthStart = calendar.date(byAdding: .month, value: -back, to: thisMonthStart)
            else {
                return false
            }
            if withReadings.contains(monthStart) { return true }
            // 订阅是规则不是观测，不进账本；那个月还在付的订阅让那个月仍然有数。
            // 两把闸都要判：只判起点的话，一笔早就退掉的订阅会把它结束之后
            // 的每个月都点亮，点进去是空的。
            let asOf = DashboardPeriod.months(back: back, count: 1)
                .anchor(now: now, calendar: calendar)
            return dashboard.ledger.subscriptions.contains {
                $0.isActive(on: asOf, calendar: calendar)
            }
        }
    }

    // MARK: - 自定义区间

    /// 自定义那一层是不是当前生效的选择。
    ///
    /// 判据是「不在上面两行里」而不是某个标记位：用户从预设 chip 一路调到
    /// 「五月–七月」再手动改回「近 3 个月」时，选中态应该自己跳回那颗 chip，
    /// 多存一个 `isCustom` 只会让两者迟早说不一样的话。
    var isCustomRange: Bool {
        guard case let .months(back, count) = draft.period else { return false }
        if count == 1 { return false }
        return back != 0 || !spanOptions.contains { $0.period == draft.period }
    }

    /// 自定义区间的起讫月（都取月首）。`YearMonthPicker` 收的是 `Date`。
    var customStartMonth: Date {
        get { monthStart(back: customWindow.oldestBack) }
        set { setCustom(oldestBack: monthsBack(from: newValue), newestBack: customWindow.newestBack) }
    }

    var customEndMonth: Date {
        get { monthStart(back: customWindow.newestBack) }
        set { setCustom(oldestBack: customWindow.oldestBack, newestBack: monthsBack(from: newValue)) }
    }

    /// 能选到的最早 / 最晚一个月。未来没有数据，上界钉在本月。
    var customLowerBound: Date { monthStart(back: DashboardFilter.maxMonthsBack) }
    var customUpperBound: Date { monthStart(back: 0) }

    /// 当前选择解析出来的窗口。进自定义那一层时把它原样搬过去，
    /// 于是「近 3 个月 → 展开自定义」看到的就是那三个月，而不是被重置成本月。
    var customWindow: MonthWindow {
        dashboard.window(for: draft)
    }

    var customMonthCount: Int { customWindow.monthCount }

    /// 起点比终点还新时对调，不报错。两个 Picker 各调各的，
    /// 中途必然经过「起 > 止」的一瞬，那一瞬弹错误是在惩罚正常操作。
    private func setCustom(oldestBack: Int, newestBack: Int) {
        let oldest = max(oldestBack, newestBack)
        let newest = min(oldestBack, newestBack)
        period = .months(back: newest, count: oldest - newest + 1)
    }

    private func monthStart(back: Int) -> Date {
        let calendar = dashboard.clock.calendar
        let now = dashboard.clock.now
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let target = calendar.date(byAdding: .month, value: -back, to: thisMonthStart)
        else {
            return now
        }
        return target
    }

    private func monthsBack(from date: Date) -> Int {
        let calendar = dashboard.clock.calendar
        let now = dashboard.clock.now
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let thatMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
            let months = calendar.dateComponents([.month], from: thatMonthStart, to: thisMonthStart).month
        else {
            return 0
        }
        return min(max(months, 0), DashboardFilter.maxMonthsBack)
    }

    // MARK: - 服务

    /// 已接入的账号。排除名单只可能包含这里面的 id。
    var availableAccounts: [AccountOption] {
        let connections = dashboard.connectionStates().filter(\.isLive)
        return connections
            .map { state in
                let descriptor = ProviderCatalog.descriptor(id: state.providerID)
                let vendor = descriptor?.displayName ?? state.providerID.rawValue
                let title = AccountTitle.context(
                    for: state.accountID,
                    connections: connections,
                    providerDisplayName: vendor
                )
                return AccountOption(
                    id: state.accountID,
                    providerID: state.providerID,
                    displayName: title.visual,
                    colorKey: descriptor?.colorKey ?? state.providerID.rawValue,
                    siblingCount: title.siblingCount,
                    vendorDisplayName: vendor
                )
            }
            .sorted { lhs, rhs in
                if lhs.vendorDisplayName != rhs.vendorDisplayName {
                    return lhs.vendorDisplayName < rhs.vendorDisplayName
                }
                return lhs.displayName < rhs.displayName
            }
    }

    var flatAccounts: [AccountOption] {
        availableAccounts.filter { $0.siblingCount <= 1 }
    }

    struct VendorGroup: Identifiable, Hashable {
        var id: ProviderID { providerID }
        var providerID: ProviderID
        var displayName: String
        var accounts: [AccountOption]
    }

    var siblingVendorGroups: [VendorGroup] {
        let siblings = availableAccounts.filter { $0.siblingCount > 1 }
        let grouped = Dictionary(grouping: siblings, by: \.providerID)
        return grouped.keys.sorted { lhs, rhs in
            let left = grouped[lhs]?.first?.vendorDisplayName ?? lhs.rawValue
            let right = grouped[rhs]?.first?.vendorDisplayName ?? rhs.rawValue
            return left < right
        }
        .compactMap { providerID in
            guard let accounts = grouped[providerID], let first = accounts.first else { return nil }
            return VendorGroup(
                providerID: providerID,
                displayName: first.vendorDisplayName,
                accounts: accounts
            )
        }
    }

    // MARK: - 预览

    /// 草稿生效之后的总数。按下之前就能看见。
    ///
    /// 走的是和仪表盘同一个入口（有账本读账本，没有就全量重算），所以面板上
    /// 预览到的数就是按下之后会看到的数——包括订阅乘对了几个月。
    ///
    /// **按草稿缓存**。这是个从 `body` 里读的派生值：不缓存的话，每次重画都要
    /// 重算一遍；点一颗 chip 会连算好几次，而其中只有最后一次的结果会被看到。
    /// `@ObservationIgnored` 是必须的——缓存不是状态，在 body 求值中写它不该触发失效。
    @ObservationIgnored private var previewCache: (draft: DashboardFilter, value: MonthToDate)?

    private var preview: MonthToDate {
        if let previewCache, previewCache.draft == draft { return previewCache.value }
        let value = LedgerProjection.compute(
            rollups: dashboard.ledger.rollups,
            subscriptions: dashboard.ledger.subscriptions,
            now: dashboard.clock.now,
            calendar: dashboard.clock.calendar,
            filter: draft
        )
        previewCache = (draft, value)
        return value
    }

    /// 和首屏同一种写法：纯金额，不挂精度记号（见 `MonthToDateModuleView` 的注释）。
    /// 口径也和首屏同一个——`totalUSD` 在关掉订阅时自己退回从量，
    /// 于是首屏切到「仅按量」时，这里预览的也是从量。
    var previewAmountText: String {
        preview.totalUSD.formatted(using: dashboard.moneyPresentation)
    }

    /// 「七月 · 不含订阅 · 排除 AWS」。什么都没筛时给一句「全部服务」占位,
    /// 免得这一行时有时无地把布局顶来顶去。
    var previewNote: String {
        let calendar = dashboard.clock.calendar
        let asOf = draft.anchor(now: dashboard.clock.now, calendar: calendar)
        return DashboardFilterSummary.full(
            filter: draft,
            window: dashboard.window(for: draft),
            asOf: asOf,
            calendar: calendar,
            connections: dashboard.connectionStates()
        )
            ?? String(localized: L("本月 · 全部服务"))
    }

    /// 一个账号都不剩时按下去只会得到 $0。允许,但要先说清楚。
    var isEverythingExcluded: Bool {
        !availableAccounts.isEmpty
            && availableAccounts.allSatisfy { draft.excludedAccounts.contains($0.id) }
    }

    // MARK: - 落地

    func apply() {
        dashboard.setFilter(draft)
    }

    func discard() {
        draft = dashboard.filter
    }
}
