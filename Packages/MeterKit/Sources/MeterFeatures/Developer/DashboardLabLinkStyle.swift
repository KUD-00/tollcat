#if DEBUG
import SwiftUI
import MeterModules

/// 实验室点不动详情，但卡上的 chevron /「查看更多」还要画出来——
/// 不注入链接壳，heatmap / 类别 / 订阅会把这些收掉，看起来像另一版模块。
enum DashboardLabLinkStyle {
    static func inert() -> ModuleLinkStyle {
        ModuleLinkStyle(
            row: { _, label in label },
            inline: { _, label in label }
        )
    }
}
#endif
