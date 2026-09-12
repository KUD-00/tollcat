import Charts
import SwiftUI

/// 本月构成：圆环 + 图例。中心不放金额——总额已经在圆环上方的主角数字里。
public struct CompositionDonut: View {
    public struct Slice: Identifiable, Sendable {
        public var id: String
        public var color: Color
        public var fraction: Double
        public var name: String
        public var amountText: String
        public var spokenAmount: String
        public var mergedNames: [String]

        public init(
            id: String,
            color: Color,
            fraction: Double,
            name: String,
            amountText: String,
            spokenAmount: String = "",
            mergedNames: [String] = []
        ) {
            self.id = id
            self.color = color
            self.fraction = fraction
            self.name = name
            self.amountText = amountText
            self.spokenAmount = spokenAmount
            self.mergedNames = mergedNames
        }
    }

    private let slices: [Slice]
    private let centerCaption: String?
    private let showsLegend: Bool
    private let size: CGFloat
    private let isAnimated: Bool
    private let isInteractive: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.compositionRevealEpoch) private var revealEpoch
    /// 渲成图片时进场动画跑不起来（`onAppear` 不跑），画的必须是满圈。
    @Environment(\.meterStaticRender) private var isStaticRender
    /// 0 是空的，1 是满的。进场从 0 转到 1；刷新时保持 1，只过渡各段角度。
    @State private var reveal: Double
    /// 按住圆环时命中的累计角度值，域和绘制值同一套（fraction × reveal 的前缀和）。
    @State private var selectedAngle: Double?

    public init(
        slices: [Slice],
        centerCaption: String? = nil,
        showsLegend: Bool = true,
        size: CGFloat = MeterSpacing.donut,
        isAnimated: Bool = true,
        isInteractive: Bool = false
    ) {
        self.slices = slices
        self.centerCaption = centerCaption
        self.showsLegend = showsLegend
        self.size = size
        self.isAnimated = isAnimated
        self.isInteractive = isInteractive
        _reveal = State(initialValue: isAnimated ? 0 : 1)
    }

    public var body: some View {
        Group {
            if !showsLegend {
                donut
            } else if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                ViewThatFits(in: .horizontal) {
                    sideBySide
                    stacked
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .onAppear(perform: playReveal)
        .onChange(of: revealEpoch) { _, _ in
            playReveal()
        }
    }

    private var sideBySide: some View {
        HStack(alignment: .center, spacing: MeterSpacing.md) {
            donut
            legend
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            donut
            legend
        }
    }

    @ViewBuilder
    private var donut: some View {
        if isInteractive {
            donutChart.chartAngleSelection(value: $selectedAngle)
        } else {
            donutChart
        }
    }

    /// 选中段外沿放大、其余压到 0.35，和柱状图按住时的压暗同一档；
    /// 浮签落在圆环中心的洞里，用的也是同一块 [ChartCalloutLabel]。
    private var donutChart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value(String(localized: L("占比")), max(slice.fraction, 0) * drawnReveal),
                innerRadius: .ratio(0.58),
                outerRadius: .ratio(outerRatio(slice)),
                angularInset: 1.5 * drawnReveal
            )
            .foregroundStyle(slice.color)
            .opacity(sliceOpacity(slice))
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            if let selected = selectedSlice {
                ChartCalloutLabel(title: selected.name, valueText: selected.amountText)
            } else if let centerCaption, !centerCaption.isEmpty {
                Text(centerCaption)
                    .font(MeterFont.caption2)
                    .foregroundStyle(Color.meterTertiaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, MeterSpacing.xs)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var selectedSlice: Slice? {
        guard isInteractive, let selectedAngle else { return nil }
        return Self.slice(at: selectedAngle, slices: slices, reveal: reveal)
    }

    /// 角度值 → 段：按绘制值（fraction × reveal）的前缀和走。给测试留的纯函数。
    static func slice(at value: Double, slices: [Slice], reveal: Double) -> Slice? {
        guard value >= 0 else { return nil }
        var cumulative = 0.0
        for slice in slices {
            cumulative += max(slice.fraction, 0) * reveal
            if value <= cumulative { return slice }
        }
        return nil
    }

    private func outerRatio(_ slice: Slice) -> Double {
        guard let selected = selectedSlice else { return 1 }
        return selected.id == slice.id ? 1 : 0.92
    }

    private func sliceOpacity(_ slice: Slice) -> Double {
        guard let selected = selectedSlice else { return 1 }
        return selected.id == slice.id ? 1 : 0.35
    }

    /// 画出来的那一份进场进度。静态渲图时恒为满圈：`reveal` 的初值是 0，
    /// 而把它拉到 1 的 `onAppear` 在 `ImageRenderer` 里永远不会跑。
    private var drawnReveal: Double {
        isStaticRender ? 1 : reveal
    }

    private func playReveal() {
        if !isAnimated || reduceMotion {
            reveal = 1
            return
        }
        var snap = Transaction()
        snap.disablesAnimations = true
        withTransaction(snap) { reveal = 0 }
        withAnimation(.smooth(duration: 0.45)) {
            reveal = 1
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            ForEach(slices) { slice in
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                    Text(slice.name)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: MeterSpacing.xs)
                    Text(slice.amountText)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
    }

    private var spokenLabel: String {
        slices.map { slice in
            let amount = slice.spokenAmount.isEmpty ? slice.amountText : slice.spokenAmount
            if slice.mergedNames.isEmpty {
                return String(localized: L("\(slice.name)，\(amount)"))
            }
            let members = slice.mergedNames.joined(separator: String(localized: L("，")))
            return String(localized: L("\(slice.name)，\(amount)，包含 \(members)"))
        }
        .joined(separator: String(localized: L("。")))
    }
}

#Preview("Light") {
    CompositionDonut(
        slices: CompositionDonutPreviewData.slices
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    CompositionDonut(
        slices: CompositionDonutPreviewData.slices
    )
    .padding(MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    CompositionDonut(
        slices: CompositionDonutPreviewData.slices
    )
    .padding(MeterSpacing.md)
    .dynamicTypeSize(.accessibility3)
}

#Preview("Interactive") {
    CompositionDonut(
        slices: CompositionDonutPreviewData.slices,
        showsLegend: false,
        isInteractive: true
    )
    .padding(MeterSpacing.md)
}

#Preview("Center caption") {
    CompositionDonut(
        slices: CompositionDonutPreviewData.slices,
        centerCaption: String(localized: L("本月构成"))
    )
    .padding(MeterSpacing.md)
}

private enum CompositionDonutPreviewData {
    static let slices = [
        CompositionDonut.Slice(id: "aws", color: MeterColor.composition(index: 0), fraction: 0.45, name: "AWS", amountText: "$21.40"),
        CompositionDonut.Slice(id: "cf", color: MeterColor.composition(index: 1), fraction: 0.23, name: "Cloudflare", amountText: "$11.05"),
        CompositionDonut.Slice(id: "oa", color: MeterColor.composition(index: 2), fraction: 0.16, name: "OpenAI", amountText: "$7.62"),
        CompositionDonut.Slice(id: "gh", color: MeterColor.composition(index: 3), fraction: 0.09, name: "GitHub", amountText: "$4.00"),
        CompositionDonut.Slice(
            id: "other",
            color: MeterColor.compositionOther,
            fraction: 0.07,
            name: "其他",
            amountText: "$3.13",
            spokenAmount: "3 美元 13 美分",
            mergedNames: ["Neon"]
        ),
    ]
}
