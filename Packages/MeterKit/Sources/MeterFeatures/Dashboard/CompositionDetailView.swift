import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct CompositionDetailView: View {
    let content: CompositionModuleContent

    @Environment(\.moneyPresentation) private var moneyPresentation

    var body: some View {
        MeterGroupedList {
            Section {
                CompositionDonut(slices: donutSlices, showsLegend: false, isInteractive: true)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityHidden(true)
            }

            Section {
                ForEach(Array(content.segments.enumerated()), id: \.element.id) { index, segment in
                    // 挂厂商的无主订阅段没有账号，但详情页本来就按厂商开，照样可点。
                    // 只有「手动订阅」段（连厂商都没有）无处可去，摆成普通行。
                    if let accountID = segment.accountID {
                        DashboardRouteLink(route: .account(accountID)) {
                            row(segment, index: index)
                        }
                        .accessibilityHint(L("查看 \(segment.displayName) 详情"))
                    } else if let providerID = segment.providerID {
                        DashboardRouteLink(route: .provider(providerID)) {
                            row(segment, index: index)
                        }
                        .accessibilityHint(L("查看 \(segment.displayName) 详情"))
                    } else {
                        row(segment, index: index)
                    }
                    // 这一段花在了哪些子服务上。和「花在哪了」全屏页同一个
                    // `SpendSublineRow`，缩进对齐色点后面的名字。
                    ForEach(segment.sublines) { subline in
                        SpendSublineRow(
                            title: subline.title,
                            amountCaption: subline.amountCaption,
                            indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                            spokenLabel: subline.spokenLabel
                        )
                    }
                }
            }
        }
        .navigationTitle(L("构成"))
        .navigationBarTitleDisplayMode(.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(spokenLabel)
    }

    private func row(_ segment: CompositionSegment, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            Circle()
                .fill(swatchColor(index: index))
                .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                .accessibilityHidden(true)
            Text(segment.displayName)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
                .lineLimit(1)
            Spacer(minLength: MeterSpacing.xs)
            Text(segment.amount.formatted(using: moneyPresentation))
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
            Text(percentText(segment.percent))
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterTertiaryLabel)
                .monospacedDigit()
        }
        .meterListRowHitTarget()
        .accessibilityLabel(
            String(localized: L("\(segment.displayName)，\(segment.amount.formatted(using: moneyPresentation))"))
        )
    }

    private var donutSlices: [CompositionDonut.Slice] {
        CompositionSlices.make(from: content.segments, presentation: moneyPresentation)
    }

    private func swatchColor(index: Int) -> Color {
        index < CompositionSlices.namedLimit
            ? MeterColor.composition(index: index)
            : MeterColor.compositionOther
    }

    private func percentText(_ percent: Int) -> String {
        "\(percent)%"
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

#Preview("Light") {
    NavigationStack {
        CompositionDetailView(content: CompositionPreviewData.sample)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CompositionDetailView(content: CompositionPreviewData.sample)
    }
    .preferredColorScheme(.dark)
}

private enum CompositionPreviewData {
    static let sample = CompositionModuleContent(
        segments: [
            CompositionSegment(
                accountID: AccountID.fixture(for: .aws),
                providerID: .aws,
                displayName: "AWS",
                colorKey: "aws",
                amount: Money(roundedUSD: 21.40),
                fraction: 0.4534,
                percent: 45,
                sublines: [
                    SpendSubline(
                        id: "EC2",
                        title: "EC2",
                        amountCaption: "$12.10",
                        spokenLabel: "EC2，12 美元 10 美分"
                    ),
                    SpendSubline(
                        id: "S3",
                        title: "S3",
                        amountCaption: "$6.30",
                        spokenLabel: "S3，6 美元 30 美分"
                    ),
                    SpendSubline(
                        id: "CloudWatch",
                        title: "CloudWatch",
                        amountCaption: "$3.00",
                        spokenLabel: "CloudWatch，3 美元"
                    ),
                ]
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
        ],
        totalText: Money(roundedUSD: 40.07).formatted(),
        spokenTotal: String(localized: L("47 美元 20 美分")),
        destination: AccountID.fixture(for: .aws)
    )
}
