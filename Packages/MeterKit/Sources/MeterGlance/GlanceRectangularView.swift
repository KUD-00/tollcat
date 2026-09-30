import SwiftUI
import WidgetKit

/// 长方形那一格（`accessoryRectangular`）：表盘的主角，智能叠放和 iPhone 锁屏也是它。
///
/// 三行：标题、金额、一句副行。副行只有一句，按轻重挑：
/// 已经超预算 > 数据旧了 > 按当前速度会超 > 预计月底。
///
/// 金额独占一整行：日文、带「US$」前缀的货币都比「$47.20」长，旁边再摆东西就只剩缩字。
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
            Text(month.amountText)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityLabel(month.spokenAmount)
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
            sublineText(Text(verbatim: budget.caption), color: GlanceStyle.color(for: .over))
        } else if let staleSince {
            sublineText(Text(GlanceText.updated(staleSince, now: now)))
        } else if let overspend = month.budget?.projectedOverspendText {
            sublineText(Text(verbatim: overspend), color: GlanceStyle.color(for: .close))
        } else if let projection = month.projectionText {
            sublineText(Text(verbatim: projection))
        }
    }

    /// 副行是这一格里唯一会报警的那句（「超出 $4.20」），字号不能掉到 caption。
    /// 手表上用 body；iPhone 锁屏那格同样三行但字号整体大一号，body 会顶出去，退到 subheadline。
    private func sublineText(_ text: Text, color: Color? = nil) -> some View {
        text
            .font(Self.sublineFont)
            .foregroundStyle(color.map(AnyShapeStyle.init) ?? AnyShapeStyle(.secondary))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    #if os(watchOS)
    private static let sublineFont = Font.body
    #else
    private static let sublineFont = Font.subheadline
    #endif

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
