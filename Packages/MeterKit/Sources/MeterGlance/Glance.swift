import Foundation

/// 手表和锁屏那一眼要的全部东西。
///
/// **iPhone 折好、排好字，原样送过来。**手表上没有账本、没有汇率表、没有凭据，
/// 也不该有：同一个数只许有一处算法（`GlanceBuilder` 读的是和仪表盘同一份
/// `DashboardContents`），这边只负责摆出来、以及判断「这份数现在还能不能这么说」。
public struct Glance: Codable, Equatable, Sendable {
    /// 载荷格式。改了字段就加一：手表和手机不一定同时升级，对不上的那份丢掉，
    /// 等下一次推送，不去猜旧格式的意思。
    public static let currentSchema = 1

    /// 多久没刷新就在表盘上说「几小时前更新」。
    ///
    /// iPhone 打开时 15 分钟内的数不重取（`UsageRefreshOnActivate.freshness`），
    /// 所以一两个小时的数是常态；三个小时没动，说明 iPhone 那边一直没开过，
    /// 这时候再摆一个看起来很新鲜的数字就是在误导。
    public static let staleAfter: TimeInterval = 3 * 60 * 60

    public var schema: Int
    /// 这份数说的是哪个月：那个月 1 号零点（按 iPhone 的日历）。
    public var monthStart: Date
    /// 下个月 1 号零点。**手表不自己算历法**：跨过这一刻就不再说「本月」，
    /// 否则 10 月 1 日的表盘会拿 9 月的合计配「本月」两个字。
    public var monthEnd: Date
    /// iPhone 折出这一份的时刻。只用来比新旧，不上屏。
    public var generatedAt: Date
    /// 账单数据最后一次成功刷新。上屏的「几分钟前」说的是这个，不是推送时刻。
    public var lastRefreshAt: Date?
    public var content: GlanceContent

    public init(
        schema: Int = Glance.currentSchema,
        monthStart: Date,
        monthEnd: Date,
        generatedAt: Date,
        lastRefreshAt: Date?,
        content: GlanceContent
    ) {
        self.schema = schema
        self.monthStart = monthStart
        self.monthEnd = monthEnd
        self.generatedAt = generatedAt
        self.lastRefreshAt = lastRefreshAt
        self.content = content
    }

    /// `lastRefreshAt` 之后多久算旧。没刷新过就没有这一刻。
    public var staleAt: Date? {
        lastRefreshAt.map { $0.addingTimeInterval(Self.staleAfter) }
    }

    /// 表盘上那几格看得见的部分。服务列表和每家的详情只在手表 App 里，
    /// 它们变了不该花复杂功能那条每天有限的额度。
    public var faceContent: GlanceContent {
        guard case .month(var month) = content else { return content }
        month.services = []
        return .month(month)
    }

    /// 同一份数换了推送时刻不算变化：省下手表那边每天有限的复杂功能推送额度。
    public func carriesSameNews(as other: Glance) -> Bool {
        schema == other.schema
            && monthStart == other.monthStart
            && monthEnd == other.monthEnd
            && lastRefreshAt == other.lastRefreshAt
            && content == other.content
    }
}
