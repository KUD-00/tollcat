import SwiftUI
import MeterCore
import MeterDesign

/// 仪表上的构成一瞥。不展开、不进详情——整张卡在外面点进去。
public struct CompositionModuleView: View {
    public let content: CompositionModuleContent
    /// 菜单栏面板传小一号；仪表盘用默认。
    public var donutSize: CGFloat = MeterSpacing.donut

    public init(content: CompositionModuleContent, donutSize: CGFloat = MeterSpacing.donut) {
        self.content = content
        self.donutSize = donutSize
    }
    @Environment(\.moneyPresentation) private var moneyPresentation

    public var body: some View {
        HStack(alignment: .center, spacing: MeterSpacing.md) {
            CompositionDonut(slices: donutSlices, showsLegend: false, size: donutSize)
            legendColumn
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .animation(DashboardMotion.number, value: content.animationSignature)
    }

    private var legendColumn: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            ForEach(legendEntries) { entry in
                HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                        .accessibilityHidden(true)
                    Text(entry.name)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: MeterSpacing.xs)
                    Text(entry.amountText)
                        .font(MeterFont.subheadline)
                        .foregroundStyle(Color.meterSecondaryLabel)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
    }

    private var legendEntries: [LegendEntry] {
        donutSlices.map { slice in
            LegendEntry(
                id: slice.id,
                name: slice.name,
                color: slice.color,
                amountText: slice.amountText
            )
        }
    }

    private var donutSlices: [CompositionDonut.Slice] {
        CompositionSlices.make(from: content.segments, presentation: moneyPresentation)
    }

    private var spokenLabel: String {
        let slices = donutSlices
        let parts = slices.map { slice -> String in
            let amount = slice.spokenAmount.isEmpty ? slice.amountText : slice.spokenAmount
            return String(localized: L("\(slice.name)，\(amount)"))
        }
        var spoken: String
        if let first = parts.first {
            spoken = parts.dropFirst().reduce(first) { String(localized: L("\($0)。\($1)")) }
        } else {
            spoken = content.spokenTotal
        }
        if let other = CompositionSlices.spokenOther(from: slices) {
            spoken = String(localized: L("\(spoken)。\(other)"))
        }
        return spoken
    }
}

private struct LegendEntry: Identifiable {
    var id: String
    var name: String
    var color: Color
    var amountText: String
}

#Preview("Light") {
    List {
        Section {
            CompositionModuleView(content: CompositionPreviewData.sample)
                .listRowSeparator(.hidden)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    List {
        Section {
            CompositionModuleView(content: CompositionPreviewData.sample)
                .listRowSeparator(.hidden)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("XXL") {
    List {
        Section {
            CompositionModuleView(content: CompositionPreviewData.sample)
                .listRowSeparator(.hidden)
        }
    }
    .dynamicTypeSize(.accessibility3)
}

/// 同 target 里的 `CompositionTileView` 预览也用这一份。
enum CompositionPreviewData {
    static let sample = CompositionModuleContent(
        segments: [
            CompositionSegment(
                accountID: AccountID.fixture(for: .aws),
                providerID: .aws,
                displayName: "AWS",
                colorKey: "aws",
                amount: Money(roundedUSD: 21.40),
                fraction: 0.4534,
                percent: 45
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                displayName: "Cloudflare",
                colorKey: "cloudflare",
                amount: Money(roundedUSD: 11.05),
                fraction: 0.2341,
                percent: 23
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                displayName: "OpenAI",
                colorKey: "openai",
                amount: Money(roundedUSD: 7.62),
                fraction: 0.1614,
                percent: 16
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .github),
                providerID: .github,
                displayName: "GitHub",
                colorKey: "github",
                amount: Money(roundedUSD: 4.00),
                fraction: 0.0847,
                percent: 9
            ),
            CompositionSegment(
                accountID: AccountID.fixture(for: .neon),
                providerID: .neon,
                displayName: "Neon",
                colorKey: "neon",
                amount: Money(roundedUSD: 3.13),
                fraction: 0.0663,
                percent: 7
            ),
        ],
        totalText: Money(roundedUSD: 47.20).formatted(),
        spokenTotal: String(localized: L("47 美元 20 美分")),
        destination: AccountID.fixture(for: .aws)
    )
}
