import SwiftUI
import WidgetKit

/// 圆形那一格，放本月金额（没设预算的人也有东西可放）。
public struct GlanceCircularAmountView: View {
    private let display: GlanceDisplay

    public init(display: GlanceDisplay) {
        self.display = display
    }

    public var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(GlanceText.monthTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GlanceStyle.accent)
                    .widgetAccentable()
                Text(verbatim: amount)
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spoken)
    }

    private var amount: String {
        if case let .month(month, _) = display { month.compactAmountText } else { "—" }
    }

    private var spoken: String {
        if case let .month(month, _) = display { GlanceText.spokenMonth(month) } else { String(localized: GlanceText.monthTitle) }
    }
}

#Preview("圆形 · 金额", traits: .fixedLayout(width: 60, height: 60)) {
    GlanceCircularAmountView(display: .resolve(GlanceSamples.month, now: GlanceSamples.now))
        .background(.black)
        .environment(\.colorScheme, .dark)
}
