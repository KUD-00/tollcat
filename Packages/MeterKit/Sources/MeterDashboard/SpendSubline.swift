import Foundation

/// 挂在服务行下面的子行：构成页和较上月同期页共用。
/// 用量段是花了钱的类别，仅订阅段是一笔笔套餐名。被额度全抵掉的用量
/// 在服务详情页的「花在哪了」看。字符串在 builder 里格式化完，view 只负责摆。
public struct SpendSubline: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var amountCaption: String
    public var spokenLabel: String
    /// 较上月同期页才填。构成页不画，避免那一页也开始说涨跌。
    public var comparisonSubtitle: String? = nil
    public var changeCaption: String? = nil
    public var changeRatio: Double? = nil

    public init(
        id: String,
        title: String,
        amountCaption: String,
        spokenLabel: String,
        comparisonSubtitle: String? = nil,
        changeCaption: String? = nil,
        changeRatio: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.amountCaption = amountCaption
        self.spokenLabel = spokenLabel
        self.comparisonSubtitle = comparisonSubtitle
        self.changeCaption = changeCaption
        self.changeRatio = changeRatio
    }
}
