import SwiftUI
import MeterDesign

struct UsageGuideArticleView: View {
    var guide: UsageGuide
    var includesTitle: Bool = true
    var catSize: CGFloat = MeterSpacing.catUsageGuide

    @Environment(\.usesPadChrome) private var usesPadChrome

    var body: some View {
        VStack(spacing: MeterSpacing.lg) {
            Spacer(minLength: MeterSpacing.md)
            CatView(mood: guide.mood, size: catSize)
            if includesTitle {
                Text(guide.title)
                    .font(MeterFont.title2)
                    .foregroundStyle(Color.meterLabel)
                    .multilineTextAlignment(.center)
            }
            Text(guide.body)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: MeterSpacing.md)
        }
        .padding(.horizontal, MeterSpacing.pageHorizontal)
        .frame(maxWidth: readableWidth)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var readableWidth: CGFloat? {
        usesPadChrome ? MeterSpacing.readableMeasure : nil
    }
}

#Preview("Light") {
    UsageGuideArticleView(guide: .make(.heroExcludesSubscriptions))
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    UsageGuideArticleView(guide: .make(.awsRefreshCostsMoney))
        .background(Color.meterGroupedBackground)
        .preferredColorScheme(.dark)
}

#Preview("XXL") {
    UsageGuideArticleView(guide: .make(.keysStayOnThisDevice))
        .background(Color.meterGroupedBackground)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Pad") {
    UsageGuideArticleView(guide: .make(.inboxForMissingAPIs))
        .background(Color.meterGroupedBackground)
        .environment(\.meterShell, .pad)
}
