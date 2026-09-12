import SwiftUI
import MeterDesign

struct UsageGuideDrawerView: View {
    var guide: UsageGuide
    var onAcknowledge: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesPadChrome) private var usesPadChrome

    var body: some View {
        NavigationStack {
            ScrollView {
                UsageGuideArticleView(guide: guide)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.meterGroupedBackground)
            .meterSheetTitle(Text(guide.title))
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

    private func acknowledge() {
        onAcknowledge()
        dismiss()
    }
}

#Preview("Light") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageGuideDrawerView(guide: .make(.heroExcludesSubscriptions), onAcknowledge: {})
        }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageGuideDrawerView(guide: .make(.awsRefreshCostsMoney), onAcknowledge: {})
        }
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageGuideDrawerView(guide: .make(.widgetOnLockScreen), onAcknowledge: {})
        }
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UsageGuideDrawerView(guide: .make(.inboxForMissingAPIs), onAcknowledge: {})
        }
        .environment(\.meterShell, .pad)
}
