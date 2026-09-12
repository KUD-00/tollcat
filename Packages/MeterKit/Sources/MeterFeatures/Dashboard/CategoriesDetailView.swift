import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 按类别构成的追查页：一个圆环，每个类别一行，行下面写清这一类含哪几家。
///
/// 类别不是账号，点不进任何一家——所以这里的行不做成链接，
/// 「含哪几家」直接写出来，省得读者再回去猜「托管」里到底装了谁。
struct CategoriesDetailView: View {
    let content: CategoriesModuleContent

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
                ForEach(Array(content.slices.enumerated()), id: \.element.id) { index, slice in
                    row(slice, index: index)
                    if !slice.memberNames.isEmpty {
                        SpendSublineRow(
                            title: slice.memberNames.joined(separator: "、"),
                            amountCaption: "",
                            indent: MeterSpacing.compositionSwatch + MeterSpacing.xs,
                            spokenLabel: String(
                                localized: L("\(String(localized: slice.title)) 含 \(slice.memberNames.joined(separator: "、"))")
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle(L("按类别构成"))
        .navigationBarTitleDisplayMode(.large)
        .accessibilityElement(children: .contain)
    }

    private func row(_ slice: CategorySlice, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            Circle()
                .fill(color(at: index))
                .frame(width: MeterSpacing.compositionSwatch, height: MeterSpacing.compositionSwatch)
                .accessibilityHidden(true)
            Text(slice.title)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
                .lineLimit(1)
            Spacer(minLength: MeterSpacing.xs)
            Text(slice.amountText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
            Text(percentText(slice.percent))
                .font(MeterFont.subheadline)
                .foregroundStyle(Color.meterTertiaryLabel)
                .monospacedDigit()
        }
        .meterListRowHitTarget()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L("\(String(localized: slice.title))，\(slice.amountText)，\(percentText(slice.percent))")
        )
    }

    private var donutSlices: [CompositionDonut.Slice] {
        content.slices.enumerated().map { index, slice in
            CompositionDonut.Slice(
                id: slice.category.rawValue,
                color: color(at: index),
                fraction: slice.fraction,
                name: String(localized: slice.title),
                amountText: slice.amountText,
                mergedNames: slice.memberNames
            )
        }
    }

    private func percentText(_ percent: Int) -> String {
        "\(percent)%"
    }

    private func color(at index: Int) -> Color {
        index < MeterColor.compositionNamedLimit
            ? MeterColor.composition(index: index)
            : MeterColor.compositionOther
    }
}

#Preview("Light") {
    NavigationStack {
        CategoriesDetailView(content: CategoriesPreviewData.sample)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CategoriesDetailView(content: CategoriesPreviewData.sample)
    }
    .preferredColorScheme(.dark)
}
