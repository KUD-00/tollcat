import SwiftUI

/// List 里 `.buttonStyle(.plain)` 的热区只包住不透明的子视图。
/// Spacer、字和金额之间的空白都点不着。铺在按钮的 **label** 上，整行都能点。
///
/// 漏铺会被 `scripts/check-source-invariants.py` 和
/// `ListRowHitTargetGuardrailTests` 拦住。
public struct ListRowHitTarget: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}

public extension View {
    func meterListRowHitTarget() -> some View {
        modifier(ListRowHitTarget())
    }

    /// iOS 的 `List` 会把按钮画成一行。Mac 默认是 NSButton 凸起，要压成行。
    /// 实现和容器级的 `meterGroupedRowButtons()` 同一套（tint / role 上色）——
    /// 以前是 `.plain`（字面色），设置页的「清除全部数据」在 Mac 上不显红，
    /// 和 iOS 对不上。
    func meterListRowButtonStyle() -> some View {
        meterGroupedRowButtons()
    }
}
