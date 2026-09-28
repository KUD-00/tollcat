#if os(watchOS)
import SwiftUI
import WidgetKit

/// 表盘角落那一格（`accessoryCorner`，只有手表有）：中间放本月金额，
/// 沿表圈弯过去的那条，预算那一种是预算弧，本月那一种是「本月」两个字。
public struct GlanceCornerView: View {
    private let display: GlanceDisplay
    private let showsBudget: Bool

    public init(display: GlanceDisplay, showsBudget: Bool) {
        self.display = display
        self.showsBudget = showsBudget
    }

    public var body: some View {
        Text(verbatim: amount)
            .font(.system(size: 20, weight: .semibold))
            .monospacedDigit()
            .minimumScaleFactor(0.5)
            .widgetCurvesContent()
            .widgetLabel {
                if showsBudget, let budget {
                    Gauge(value: min(max(budget.fraction, 0), 1)) {
                        Text(GlanceText.budgetTitle)
                    }
                    .tint(GlanceStyle.color(for: budget.level))
                } else {
                    Text(GlanceText.monthTitle)
                        .foregroundStyle(GlanceStyle.accent)
                }
            }
            .accessibilityLabel(spoken)
    }

    private var month: GlanceMonth? {
        if case let .month(month, _) = display { month } else { nil }
    }

    private var amount: String { month?.compactAmountText ?? "—" }

    private var budget: GlanceBudget? { month?.budget }

    private var spoken: String {
        month.map(GlanceText.spokenMonth) ?? String(localized: GlanceText.monthTitle)
    }
}
#endif
