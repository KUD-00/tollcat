import SwiftUI
import MeterCore
import MeterDesign

/// 更新后第一次冷启动那张抽屉。
///
/// 跳版会合并：最新那条当 hero，被跳过的版本折在下面一行「更多更新」里——
/// 不铺成三段，那样第一屏就读不完。全文在设置 → 关于 → 更新说明。
struct WhatsNewDrawerView: View {
    /// 新的在上。至少一条，由 `WhatsNewLaunch.pending` 保证。
    var entries: [WhatsNewEntry]
    var onAcknowledge: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesPadChrome) private var usesPadChrome

    private var language: CatalogLanguage { CatalogDisplay.language }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MeterSpacing.md) {
                    if let latest = entries.first {
                        WhatsNewEntryView(entry: latest)
                    }
                    if entries.count > 1 {
                        skipped
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.meterGroupedBackground)
            .meterSheetTitle(Text(L("更新说明")))
            .meterSheetClose { acknowledge() }
            .meterPrimaryActionBar {
                Button(action: acknowledge) {
                    Text(L("知道了"))
                        .frame(maxWidth: usesPadChrome ? MeterSpacing.readableMeasure : .infinity)
                }
                .meterPrimaryActionStyle()
                .frame(maxWidth: usesPadChrome ? MeterSpacing.readableMeasure : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .meterDrawerChrome(.mediumLarge, usesPadChrome: usesPadChrome)
    }

    /// 被跳过的那几版：只列标题，一行一版。想看全文去设置。
    private var skipped: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(L("更多更新"))
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
            ForEach(Array(entries.dropFirst())) { entry in
                Text(verbatim: "\(entry.version) · \(entry.title.resolved(language))")
                    .font(MeterFont.subheadline)
                    .foregroundStyle(Color.meterLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: usesPadChrome ? MeterSpacing.readableMeasure : nil, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: usesPadChrome ? .center : .leading)
        .padding(.horizontal, MeterSpacing.pageHorizontal)
        .padding(.bottom, MeterSpacing.lg)
    }

    private func acknowledge() {
        onAcknowledge()
        dismiss()
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewDrawerView(entries: [.preview], onAcknowledge: {})
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewDrawerView(entries: [.preview], onAcknowledge: {})
        }
        .preferredColorScheme(.dark)
}

#Preview("跳过两版") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewDrawerView(
                entries: [.preview, .previewOlder],
                onAcknowledge: {}
            )
        }
}

#Preview("XXL") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewDrawerView(entries: [.preview], onAcknowledge: {})
        }
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewDrawerView(entries: [.preview], onAcknowledge: {})
        }
        .environment(\.meterShell, .pad)
}
