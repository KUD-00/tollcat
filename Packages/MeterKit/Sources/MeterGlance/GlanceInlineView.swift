import SwiftUI

/// 行内那一格（`accessoryInline`）：一行字，系统会截断，所以只放本月金额。
public struct GlanceInlineView: View {
    private let display: GlanceDisplay

    public init(display: GlanceDisplay) {
        self.display = display
    }

    public var body: some View {
        switch display {
        case let .month(month, _):
            Text(GlanceText.monthInline(month.amountText))
                .accessibilityLabel(GlanceText.spokenMonth(month))
        case .noBills:
            Text(GlanceText.noBills)
        case .waitingForMonth:
            Text(GlanceText.waitingForMonth)
        case .neverSynced:
            Text(GlanceText.neverSynced)
        }
    }
}

#Preview("行内") {
    GlanceInlineView(display: .resolve(GlanceSamples.month, now: GlanceSamples.now))
}
