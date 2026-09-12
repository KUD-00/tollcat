import SwiftUI

/// 刷新按钮进行中：不可点，VoiceOver 说正在刷新。箭头怎么转由 `MeterRefreshGlyph` 管。
public struct MeterRefreshing: ViewModifier {
    var isRefreshing: Bool

    public func body(content: Content) -> some View {
        content
            .disabled(isRefreshing)
            .accessibilityAddTraits(isRefreshing ? .updatesFrequently : [])
            .accessibilityValue(isRefreshing ? Text(L("正在刷新")) : Text(""))
    }
}

public extension View {
    func meterRefreshing(_ isRefreshing: Bool) -> some View {
        modifier(MeterRefreshing(isRefreshing: isRefreshing))
    }
}
