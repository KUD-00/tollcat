import SwiftUI
import WidgetKit

/// 圆形那一格，放预算圆环。系统的 capacity 样式：表盘着色时跟着变单色，不用自己画环。
public struct GlanceCircularBudgetView: View {
    private let display: GlanceDisplay

    public init(display: GlanceDisplay) {
        self.display = display
    }

    public var body: some View {
        Gauge(value: fraction) {
            Text(GlanceText.budgetTitle)
        } currentValueLabel: {
            Text(verbatim: valueText)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .widgetAccentable()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var budget: GlanceBudget? {
        if case let .month(month, _) = display { month.budget } else { nil }
    }

    /// 圆环画满为止；超出去的那截由百分比和红色说。
    private var fraction: Double { min(max(budget?.fraction ?? 0, 0), 1) }

    private var valueText: String { budget?.percentText ?? "—" }

    private var tint: Color { budget.map { GlanceStyle.color(for: $0.level) } ?? .gray }

    private var spoken: String {
        guard let budget else { return String(localized: GlanceText.noBudget) }
        return budget.spokenLabel
    }
}

#Preview("圆形 · 预算", traits: .fixedLayout(width: 60, height: 60)) {
    GlanceCircularBudgetView(display: .resolve(GlanceSamples.month, now: GlanceSamples.now))
        .background(.black)
        .environment(\.colorScheme, .dark)
}
