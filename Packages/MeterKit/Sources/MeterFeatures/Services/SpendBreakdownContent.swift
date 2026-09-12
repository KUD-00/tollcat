import Foundation
import MeterCore

/// 明细分组的两个维度。`scope` 那一维不是每家都有，能不能选由内容决定。
///
/// 定义在 `MeterCore/SpendGrouping`：Android 桥要同一份分组规则，而它链不了 Features。
typealias SpendBreakdownGrouping = SpendGroupingMode

/// 详情页「花在哪了」那一节的全部内容。**字符串在 builder 里就格式化完**，
/// 和 `ProviderDetailHistoryItem` 一个路子：view 只负责摆，不碰领域类型。
struct SpendBreakdownContent: Equatable, Sendable {
    var groups: [SpendBreakdownGroup]
    /// 能不能切到「按归属」。整份明细一个 `scope` 都没有时是 false，界面不出选择器。
    var supportsScopeGrouping: Bool
    /// 明细自身的合计。**不等于快照的 `currentSpendUSD`**——见 `Snapshot.lines` 的说明。
    var totalCaption: String
    /// 「原价 $10.19，额度抵扣 $10.19」这一行。没有原价信息时是 nil。
    var discountCaption: String?
    /// 原始明细条数，用于「全部 N 项」那个入口。不是分组数——折叠成「其他」的也算。
    var itemCount: Int
    var spokenSummary: String

    var isEmpty: Bool { groups.isEmpty }

    /// 详情页「本月」底下最多列几组。三条是一节里能撑起版式又不喧宾夺主的量：
    /// 再多这一节会比它上面的「本月」还高。
    static let previewGroupLimit = 3

    /// 详情页只列真花了钱的组。$0 那几行是「额度挡了什么」，留给全屏页；
    /// 拿它们把三个槽位凑满，等于在大数字下面重复写三遍零。
    var previewGroups: [SpendBreakdownGroup] {
        Array(groups.filter { !$0.isZeroBilled }.prefix(Self.previewGroupLimit))
    }

    static let empty = SpendBreakdownContent(
        groups: [],
        supportsScopeGrouping: false,
        totalCaption: "—",
        discountCaption: nil,
        itemCount: 0,
        spokenSummary: ""
    )
}

struct SpendBreakdownGroup: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var amountCaption: String
    /// 占明细合计的比例，`0...1`。合计为 0（全被免费额度抵掉）时按用量比例退化，
    /// 否则一屏的条全是空的、看不出谁烧得多。
    var fraction: Double
    /// 「71%」。**只有真花了钱才给**——合计为 0 时 `fraction` 是用量占比，
    /// 拿它写成百分比会被读成"花了七成"。
    var shareCaption: String?
    /// 「1,667 Minutes」这类用量说明。单位对不齐的组没有。
    var detailCaption: String?
    /// 「额度抵扣 $10.00」。这一句在全免费的家里是唯一有信息量的数字，
    /// 金额那一列全是 $0.00。
    var allowanceCaption: String?
    /// 实收到分都是 0。详情页预览不拿这种组去凑三个槽位。
    var isZeroBilled: Bool
    var items: [SpendBreakdownItem]
    var spokenLabel: String
}

struct SpendBreakdownItem: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var amountCaption: String
    var detailCaption: String?
    /// 「原价 $0.35」。实收和原价一样时不显示——没被抵扣就没有可说的。
    var listCaption: String?
    var spokenLabel: String
}
