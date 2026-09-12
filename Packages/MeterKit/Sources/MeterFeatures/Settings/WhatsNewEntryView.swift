import SwiftUI
import MeterCore
import MeterDesign

/// 一条更新说明的正文：hero、标题、然后符号 + 标题 + 正文的列表。
/// 抽屉和设置里的全量列表共用它，两处不许各排一遍版。
struct WhatsNewEntryView: View {
    var entry: WhatsNewEntry
    /// 全量列表里标题已经在导航栏上了，正文不用再写一遍。
    var includesTitle: Bool = true

    @Environment(\.usesPadChrome) private var usesPadChrome

    private var language: CatalogLanguage { CatalogDisplay.language }

    var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.lg) {
            if let hero = entry.hero {
                WhatsNewHeroView(hero: hero)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            if includesTitle {
                Text(entry.title.resolved(language))
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: MeterSpacing.lg) {
                ForEach(entry.items) { item in
                    row(item)
                }
            }
        }
        .padding(.vertical, MeterSpacing.lg)
        .padding(.horizontal, MeterSpacing.pageHorizontal)
        .frame(maxWidth: usesPadChrome ? MeterSpacing.readableMeasure : nil)
        .frame(maxWidth: .infinity)
    }

    private func row(_ item: WhatsNewItem) -> some View {
        HStack(alignment: .top, spacing: MeterSpacing.md) {
            if let symbol = item.symbol {
                Image(systemName: symbol)
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: MeterSpacing.xl, alignment: .center)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: MeterSpacing.xs / 2) {
                Text(item.title.resolved(language))
                    .font(MeterFont.bodyEmphasized)
                    .foregroundStyle(Color.meterLabel)
                Text(item.body.resolved(language))
                    .font(MeterFont.body)
                    .foregroundStyle(Color.meterSecondaryLabel)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    ScrollView { WhatsNewEntryView(entry: .preview) }
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ScrollView { WhatsNewEntryView(entry: .preview) }
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    ScrollView { WhatsNewEntryView(entry: .preview) }
        .background(Color.meterGroupedBackground)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    ScrollView { WhatsNewEntryView(entry: .preview) }
        .background(Color.meterGroupedBackground)
        .environment(\.meterShell, .pad)
}
