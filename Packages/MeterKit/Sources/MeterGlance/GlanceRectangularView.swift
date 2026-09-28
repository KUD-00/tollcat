import SwiftUI
import WidgetKit

/// 长方形那一格（`accessoryRectangular`）：表盘的主角，智能叠放和 iPhone 锁屏也是它。
///
/// 三行：标题、金额（右边一条本月走势）、一句副行。副行只有一句，按轻重挑：
/// 已经超预算 > 数据旧了 > 按当前速度会超 > 预计月底。
public struct GlanceRectangularView: View {
    private let display: GlanceDisplay
    private let now: Date

    public init(display: GlanceDisplay, now: Date) {
        self.display = display
        self.now = now
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(GlanceText.monthTitle)
                .font(.headline)
                .foregroundStyle(GlanceStyle.accent)
                .widgetAccentable()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        switch display {
        case let .month(month, staleSince):
            HStack(alignment: .center, spacing: 6) {
                Text(month.amountText)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityLabel(month.spokenAmount)
                Spacer(minLength: 0)
                if let trend = month.trend {
                    GlanceSparkline(trend: trend, lineWidth: 2)
                        .foregroundStyle(GlanceStyle.accent)
                        .frame(width: 52, height: 24)
                        .widgetAccentable()
                }
            }
            subline(month, staleSince: staleSince)
        case .noBills:
            headline(GlanceText.noBills)
            caption(GlanceText.noBillsHint)
        case .waitingForMonth:
            headline("—")
            caption(GlanceText.waitingForMonth)
        case .neverSynced:
            caption(GlanceText.neverSynced)
        }
    }

    @ViewBuilder
    private func subline(_ month: GlanceMonth, staleSince: Date?) -> some View {
        if let budget = month.budget, budget.level == .over {
            caption(budget.caption, color: GlanceStyle.color(for: .over))
        } else if let staleSince {
            caption(GlanceText.updated(staleSince, now: now))
        } else if let overspend = month.budget?.projectedOverspendText {
            caption(overspend, color: GlanceStyle.color(for: .close))
        } else if let projection = month.projectionText {
            caption(projection)
        }
    }

    private func headline(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func headline(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.headline)
    }

    private func caption(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }

    private func caption(_ text: String, color: Color? = nil) -> some View {
        Text(verbatim: text)
            .font(.caption)
            .foregroundStyle(color.map(AnyShapeStyle.init) ?? AnyShapeStyle(.secondary))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

#Preview("长方形", traits: .fixedLayout(width: 184, height: 76)) {
    VStack(spacing: 12) {
        GlanceRectangularView(display: .resolve(GlanceSamples.month, now: GlanceSamples.now), now: GlanceSamples.now)
        GlanceRectangularView(display: .resolve(GlanceSamples.overBudget, now: GlanceSamples.now), now: GlanceSamples.now)
        GlanceRectangularView(display: .resolve(GlanceSamples.stale, now: GlanceSamples.now), now: GlanceSamples.now)
        GlanceRectangularView(display: .noBills, now: GlanceSamples.now)
    }
    .padding(8)
    .background(.black)
    .environment(\.colorScheme, .dark)
}
