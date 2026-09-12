import SwiftUI

/// 刷新箭头。进行中时按系统符号效果连续转，直到调用方把 `isRefreshing` 关掉。
public struct MeterRefreshGlyph: View {
    var isRefreshing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isRefreshing: Bool) {
        self.isRefreshing = isRefreshing
    }

    public var body: some View {
        Image(systemName: "arrow.clockwise")
            .symbolEffect(
                .rotate,
                options: .repeat(.continuous),
                isActive: isRefreshing && !reduceMotion
            )
    }
}

#Preview("Idle · Light") {
    MeterRefreshGlyphPreview(isRefreshing: false)
        .preferredColorScheme(.light)
}

#Preview("Idle · Dark") {
    MeterRefreshGlyphPreview(isRefreshing: false)
        .preferredColorScheme(.dark)
}

#Preview("Refreshing · Light") {
    MeterRefreshGlyphPreview(isRefreshing: true)
        .preferredColorScheme(.light)
}

#Preview("Refreshing · Dark") {
    MeterRefreshGlyphPreview(isRefreshing: true)
        .preferredColorScheme(.dark)
}

private struct MeterRefreshGlyphPreview: View {
    var isRefreshing: Bool

    var body: some View {
        MeterRefreshGlyph(isRefreshing: isRefreshing)
            .font(MeterFont.title2)
            .padding(MeterSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.meterGroupedBackground)
    }
}
