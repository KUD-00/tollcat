import SwiftUI

/// 构成条。参照系统「储存空间」：细胶囊、段与段无缝。
public struct SegmentBar: View {
    private let segments: [(color: Color, fraction: Double)]
    private let height: CGFloat

    public init(
        segments: [(color: Color, fraction: Double)],
        height: CGFloat = MeterSpacing.segmentBar
    ) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    let fraction = max(segment.fraction, 0)
                    if fraction > 0 {
                        segment.color
                            .frame(width: proxy.size.width * fraction)
                    }
                }
            }
        }
        .frame(height: height)
        .background(Color.meterTertiarySystemFill)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    SegmentBar(
        segments: [
            (MeterColor.composition(index: 0), 0.45),
            (MeterColor.composition(index: 1), 0.23),
            (MeterColor.composition(index: 2), 0.16),
            (MeterColor.composition(index: 3), 0.09),
            (MeterColor.compositionOther, 0.07),
        ]
    )
    .padding(MeterSpacing.pageHorizontal)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    SegmentBar(
        segments: [
            (MeterColor.composition(index: 0), 0.45),
            (MeterColor.composition(index: 1), 0.23),
            (MeterColor.composition(index: 2), 0.16),
            (MeterColor.composition(index: 3), 0.09),
            (MeterColor.compositionOther, 0.07),
        ],
        height: MeterSpacing.segmentBarWidget
    )
    .padding(MeterSpacing.pageHorizontal)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}
