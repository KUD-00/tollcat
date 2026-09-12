import Foundation
import MeterCore

/// 共享 SwiftData store 里已经落下的读数。折算不入库，每次现算。
public struct SharedStoreContents: Sendable {
    /// Widget 那一屏的输入。**读模型，不是快照日志**——小组件跑在独立进程里，
    /// 每次时间线刷新都重放一遍日志的代价和主 App 一样大，而它连界面都没打开。
    public var view: LedgerView
    public var subscriptions: [MonthlySubscription]
    public var lastSuccessfulRefreshAt: Date?
    public var connectedAccountCount: Int
    /// 加进服务列表的厂商数。没有用量身份也可以 > 0。
    public var connectedVendorCount: Int
    public var displayCurrency: String
    /// 首屏那颗口径切换落盘的值。Widget 跟它，两边才说同一个数。
    public var includesSubscriptions: Bool
    /// 已接入的账号。Widget 靠它把「AWS · 工作」这种多账号标题读对——
    /// 没有它就只能显示厂商名，和 App 里的行对不上。
    public var connections: [ProviderConnectionState]
    /// 用户编辑过的仪表盘版式：开了哪些模块、钉了哪几家、预算多少。
    /// Widget 能选的模块必须是**用户仪表盘上有的**那些，所以这份也要过来。
    public var layout: DashboardLayout

    public init(
        view: LedgerView,
        subscriptions: [MonthlySubscription],
        lastSuccessfulRefreshAt: Date?,
        connectedAccountCount: Int = 0,
        connectedVendorCount: Int = 0,
        displayCurrency: String = ExchangeRates.usdCode,
        includesSubscriptions: Bool = false,
        connections: [ProviderConnectionState] = [],
        layout: DashboardLayout = .default
    ) {
        self.view = view
        self.subscriptions = subscriptions
        self.lastSuccessfulRefreshAt = lastSuccessfulRefreshAt
        self.connectedAccountCount = connectedAccountCount
        self.connectedVendorCount = connectedVendorCount
        self.displayCurrency = displayCurrency
        self.includesSubscriptions = includesSubscriptions
        self.connections = connections
        self.layout = layout
    }

    /// Widget 的取景框：**只跟订阅口径**，不跟排除名单和月份——
    /// Widget 永远是「本月 · 全部账号」。构造收在这儿，Widget 源码不出现
    /// 取景框类型（`DashboardFilterScopeTests` 的守卫），想跟别的维度
    /// 必须先过这条注释和 SPEC 12.5。
    public var widgetFilter: DashboardFilter {
        DashboardFilter(includesSubscriptions: includesSubscriptions)
    }

    /// 还没写过任何账单读数。这时总数是「没有」，不是 $0。
    public var isEmpty: Bool {
        view.rollups.isEmpty && subscriptions.isEmpty
    }

    /// 这份账本**说得了 `now` 那个月的事吗**。
    ///
    /// 折叠是主 App 的活，Widget 折不了。账本折的时候把某一刻当「今天」，
    /// 而它只铺到那一刻往回数的那些月——跨月之后，新的那个月在账本里一行都没有。
    /// 拿它按「本月」投影会得到一个 $0，而屏幕上 $0 和「这个月真的没花钱」
    /// 长得一模一样，主屏又是最不会有人去核对的地方。
    ///
    /// 所以跨月之后 Widget 该说「暂时没有数据」，而不是摆一个 0，
    /// 更不是继续摆上个月的数字配这个月的月份名。
    public func canSpeak(for now: Date, calendar: Calendar) -> Bool {
        guard let foldedAsOf = view.rollups.map(\.foldedAsOf).max() else {
            // 一行都没有：要么真是空库（`isEmpty` 会先拦下），要么账本还没写好，
            // 两种都不该由 Widget 编一个数出来。
            return false
        }
        return calendar.isDate(foldedAsOf, equalTo: now, toGranularity: .month)
    }
}
