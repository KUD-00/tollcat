import SwiftUI

#if os(macOS)
/// grouped `Form` 的 section 卡。系统那张卡是「画布 × 4% 黑」——只会比画布更暗
/// （深色反过来是加白，更亮），和 iOS insetGrouped、和仪表盘 bento 的「白卡压灰画布」
/// 正好反过来：浅色下 #F2F2F7 的画布配出 #EBEBF0 的卡，整页看着一片灰。
///
/// 那张卡由 grouped `FormStyle` 通过 `GroupBox` 画，所以接管 `groupBoxStyle` 就能换底色。
/// `configuration.content` 已经带好行高、行内边距和行间分隔线，版式和系统卡逐像素一致
/// （量过角上曲线：12pt 连续圆角与系统卡重合），只有底色换成 token。
/// `.listRowBackground`、`.backgroundStyle`、`Section {}.background()` 都动不了它——
/// 三个都试过，Form 不是 List，前两个是 no-op，第三个只糊在标签底下。
struct MeterGroupedSectionBox: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .background(
                Color.meterSecondaryGroupedBackground,
                in: RoundedRectangle(cornerRadius: MeterRadius.macGroupedSection, style: .continuous)
            )
    }
}
#endif

public extension View {
    /// 挂在分组容器（grouped `Form`）上：Mac 的 section 卡改成和仪表盘模块同一张卡面
    /// （`meterSecondaryGroupedBackground`，浅色纯白 / 深色 #2C2C2E）。
    /// `MeterGroupedList` 自带；直接写 `Form { }.formStyle(.grouped)` 的页面要自己挂——
    /// `MacColumnGuardrailTests` 按这个规则扫。iOS 是 no-op：insetGrouped 的行卡本来就是这个色。
    @ViewBuilder
    func meterGroupedSectionCard() -> some View {
        #if os(macOS)
        groupBoxStyle(MeterGroupedSectionBox())
        #else
        self
        #endif
    }
}
