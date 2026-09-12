import SwiftUI

/// 三格信号。满格表示完全支持，少格表示有限或走信箱。
public struct SupportSignalBars: View {
    public var filled: Int
    public var tint: Color

    public init(filled: Int, tint: Color) {
        self.filled = min(Self.barCount, max(0, filled))
        self.tint = tint
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: Self.gap) {
            ForEach(0..<Self.barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                    .fill(index < filled ? tint : Color.meterTertiaryLabel.opacity(0.28))
                    .frame(width: Self.width, height: Self.heights[index])
            }
        }
        .accessibilityHidden(true)
    }

    private static let barCount = 3
    private static let width: CGFloat = 3
    private static let gap: CGFloat = 2
    private static let corner: CGFloat = 0.6
    private static let heights: [CGFloat] = [5, 9, 13]
}

#Preview("Light") {
    SupportSignalBarsPreviewLibrary()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SupportSignalBarsPreviewLibrary()
        .preferredColorScheme(.dark)
}

private struct SupportSignalBarsPreviewLibrary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.md) {
            labeled(3, MeterColor.good)
            labeled(2, MeterColor.warn)
            labeled(1, Color.accentColor)
            labeled(0, Color.meterTertiaryLabel)
        }
        .padding(MeterSpacing.pageHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.meterGroupedBackground)
    }

    private func labeled(_ filled: Int, _ tint: Color) -> some View {
        HStack(spacing: MeterSpacing.xs) {
            SupportSignalBars(filled: filled, tint: tint)
            Text(verbatim: "\(filled)")
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
        }
    }
}
