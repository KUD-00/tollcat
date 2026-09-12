import SwiftUI

public enum MeterRadius {
    /// 28pt Provider tile。按系统 App 图标约 22% 边长取 6，才能是 continuous 方块而不是胶囊。
    public static let glyph: CGFloat = 6
    /// 热力格的圆角。
    public static let heatCell: CGFloat = 3
    /// 预算线小方块的圆角。跟热力格同一档，两处格子看着是一家。
    public static let budgetBlock: CGFloat = 3
    /// 2×2 小组件里那一格只有 10pt 宽，圆角要跟着收，否则一排格子看着像一排点。
    public static let budgetBlockCompact: CGFloat = 2

    /// 教程步骤序号。圆角方形，不要圆到胶囊。
    public static let stepBadge: CGFloat = 8

    /// 系统搜索栏那种连续圆角。
    public static let searchField: CGFloat = 10

    /// 自己画的卡片（分享面板的预览、动作区）。系统 inset-grouped 的行卡由
    /// `List` 自己画，不走这里。
    public static let card: CGFloat = 16

    /// Mac grouped `Form` 的 section 卡（`meterGroupedSectionCard`）。12 是照 macOS 26
    /// 的系统卡量出来的连续圆角：角上曲线横向铺 9pt，r=11 只有 8pt、r=14 是 11pt。
    public static let macGroupedSection: CGFloat = 12

    /// 仪表猫要坐在卡沿上，List 的 section 会裁掉伸出的部分，只能自己画一张同色的卡。
    /// 26 是 iOS 26 inset-grouped 的连续圆角。
    public static let groupedCard: CGFloat = 26
}
