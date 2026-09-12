import SwiftUI

/// 糖果 / 咖啡 / 披萨。装饰，热区在外面的购买按钮上。
public struct TipTreatView: View {
    public var kind: TipTreatKind
    public var size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(kind: TipTreatKind, size: CGFloat) {
        self.kind = kind
        self.size = size
    }

    public var body: some View {
        let aspect = TipTreatArtwork.viewBox.height / TipTreatArtwork.viewBox.width
        Canvas(opaque: false, rendersAsynchronously: false) { context, canvas in
            var drawing = context
            TipTreatArtwork.draw(
                kind,
                in: &drawing,
                canvas: canvas,
                scheme: colorScheme
            )
        }
        .frame(width: size, height: size * aspect)
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    TipTreatPreviewRow()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TipTreatPreviewRow()
        .preferredColorScheme(.dark)
}

private struct TipTreatPreviewRow: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: MeterSpacing.lg) {
            ForEach(TipTreatKind.allCases, id: \.self) { kind in
                VStack(spacing: MeterSpacing.xs) {
                    TipTreatView(kind: kind, size: MeterSpacing.tipTreat)
                    Text(kind.rawValue)
                        .font(MeterFont.caption)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
            }
        }
        .padding(MeterSpacing.pageHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.meterGroupedBackground)
    }
}
