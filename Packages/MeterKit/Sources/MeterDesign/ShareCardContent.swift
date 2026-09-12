import Foundation

/// 分享卡上要画的东西。
///
/// 全是已经格式化好的字符串和 0–1 的比例，**不认识任何领域类型**——
/// MeterDesign 只认 SwiftUI（ARCHITECTURE.md）。`Money` 怎么变成 "$47.20"，
/// 在 MeterFeatures 里决定完再传进来。
///
/// 字段跟着仪表首屏：主角数字、构成环、较上月同期、近几个月。
/// 卡是一张独立的图，收件人看不到导航标题，所以月份也要写在卡上。
public struct ShareCardContent: Hashable, Sendable {
    /// 「八月」。仪表上这是大标题；卡上看不到导航栏，写在数字上面、同一档。
    public var periodTitle: String
    /// 「$47.20」。
    public var totalText: String
    /// 「预计月底 $94 · 8/1–8/17」。没有就不画这一行。
    public var projectionText: String?
    /// 「本月订阅 $4 · 已计入」。没有就不画。跟仪表同一口径，不另开开关。
    public var subscriptionText: String?
    /// 「按人民币显示」。美元不写。
    public var currencyNote: String?
    public var segments: [Segment]
    /// 较上月同期那张方卡。没有就不画。
    public var comparison: Comparison?
    /// 近几个月那张方卡。没有就不画。
    public var trend: Trend?
    /// 「七月 · 不含订阅 · 排除 AWS」。没筛过就是 nil。
    ///
    /// **筛过的卡必须自己说清楚筛了什么。** 这张图会被转发到我们看不见的
    /// 地方，收到的人没有任何别的途径知道那个数字漏了什么；一张不带限定语的
    /// 筛选后账单就是一张假账单。
    public var filterNote: String?
    public var qrPayload: String
    /// 品牌主句。落款和站点页脚同一句，不另写自我介绍。
    public var qrCaption: String
    /// 二维码指向的主机名。码被压缩扫不出时还能手打。
    public var footnote: String

    public struct Segment: Hashable, Sendable, Identifiable {
        public var name: String
        /// 已经格式化的金额。
        public var amountText: String
        public var fraction: Double
        /// 第 5 名之后合并的「其他」。颜色走 `MeterColor.compositionOther`。
        public var isOther: Bool

        public var id: String { name }

        public init(name: String, amountText: String, fraction: Double, isOther: Bool = false) {
            self.name = name
            self.amountText = amountText
            self.fraction = fraction
            self.isOther = isOther
        }
    }

    public struct Comparison: Hashable, Sendable {
        public var title: String
        public var percentText: String
        public var caption: String?
        public var current: Double
        public var previous: Double?
        public var currentLabel: String
        public var previousLabel: String
        public var tone: Tone
        /// 没有可比的上月同期时只写百分数，不画一根孤零零的柱。
        public var showsBars: Bool

        public enum Tone: Hashable, Sendable {
            case up
            case down
            case flat
            case unknown
        }

        public init(
            title: String,
            percentText: String,
            caption: String?,
            current: Double,
            previous: Double?,
            currentLabel: String,
            previousLabel: String,
            tone: Tone,
            showsBars: Bool
        ) {
            self.title = title
            self.percentText = percentText
            self.caption = caption
            self.current = current
            self.previous = previous
            self.currentLabel = currentLabel
            self.previousLabel = previousLabel
            self.tone = tone
            self.showsBars = showsBars
        }
    }

    public struct Trend: Hashable, Sendable {
        public var title: String
        public var points: [PlotPoint]
        public var xStart: Date
        public var xEnd: Date
        public var highlight: Date

        public init(
            title: String,
            points: [PlotPoint],
            xStart: Date,
            xEnd: Date,
            highlight: Date
        ) {
            self.title = title
            self.points = points
            self.xStart = xStart
            self.xEnd = xEnd
            self.highlight = highlight
        }
    }

    public init(
        periodTitle: String,
        totalText: String,
        projectionText: String?,
        subscriptionText: String? = nil,
        currencyNote: String? = nil,
        segments: [Segment],
        comparison: Comparison? = nil,
        trend: Trend? = nil,
        filterNote: String? = nil,
        qrPayload: String,
        qrCaption: String,
        footnote: String
    ) {
        self.periodTitle = periodTitle
        self.totalText = totalText
        self.projectionText = projectionText
        self.subscriptionText = subscriptionText
        self.currencyNote = currencyNote
        self.segments = segments
        self.comparison = comparison
        self.trend = trend
        self.filterNote = filterNote
        self.qrPayload = qrPayload
        self.qrCaption = qrCaption
        self.footnote = footnote
    }
}
