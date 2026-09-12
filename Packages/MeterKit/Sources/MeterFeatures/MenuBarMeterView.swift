import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat
import MeterModules

/// 菜单栏点开之后的面板。搬的是仪表盘首屏那几样：数字、预计、构成条、近几个月。
/// 只读主 App 上次写下的数，自己不打账单 API。口径跟仪表盘取景框，
/// 筛过的话限定语和数字一起出现，不会只剩一个看起来正常的数。
public struct MenuBarMeterView: View {
    var dashboard: DashboardModel
    var onOpenMainWindow: () -> Void
    var onQuit: () -> Void

    public init(
        dashboard: DashboardModel,
        onOpenMainWindow: @escaping () -> Void,
        onQuit: @escaping () -> Void = {}
    ) {
        self.dashboard = dashboard
        self.onOpenMainWindow = onOpenMainWindow
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.sm) {
            header
            if let composition = dashboard.compositionContent {
                compositionBlock(composition)
            }
            if let trend = dashboard.trendContent {
                trendBlock(trend)
            }
            if let failure = dashboard.refreshFailureCaption {
                Text(failure)
                    .font(MeterFont.footnote)
                    .foregroundStyle(MeterColor.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            actions
        }
        .padding(MeterSpacing.md)
        .frame(width: MeterSpacing.macMenuBarPanelWidth)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: MeterSpacing.md) {
            VStack(alignment: .leading, spacing: MeterSpacing.xxs) {
                if let content = dashboard.monthToDateContent {
                    Text(content.filterNote ?? String(localized: L("本月")))
                        .font(MeterFont.caption)
                        .foregroundStyle(Color.meterTertiaryLabel)
                        .lineLimit(2)
                    Text(content.amountText)
                        .font(MeterFont.title.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.meterLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .accessibilityLabel(content.spokenTotal)
                    if let projected = content.fullProjectedCaption {
                        Text(projected)
                            .font(MeterFont.subheadline)
                            .foregroundStyle(Color.meterSecondaryLabel)
                            .monospacedDigit()
                            .accessibilityLabel(content.spokenProjected ?? projected)
                    }
                    if let stale = content.staleCaption {
                        Text(stale)
                            .font(MeterFont.footnote)
                            .foregroundStyle(MeterColor.warn)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(L("还没有账单"))
                        .font(MeterFont.bodyEmphasized)
                        .foregroundStyle(Color.meterLabel)
                    Text(L("打开 App 接入第一家服务"))
                        .font(MeterFont.caption)
                        .foregroundStyle(Color.meterSecondaryLabel)
                }
            }
            Spacer(minLength: 0)
            if !dashboard.shell.hidesCat {
                CatView(
                    mood: MeterDesign.CatMood(dashboard.catMood),
                    size: MeterSpacing.catWidget,
                    isAnimated: false
                )
            }
        }
    }

    /// 饼图在左、图例在右，和仪表盘构成卡同一个视图。
    private func compositionBlock(_ content: CompositionModuleContent) -> some View {
        CompositionModuleView(content: content, donutSize: MeterSpacing.donutMenuBar)
            .environment(\.moneyPresentation, dashboard.moneyPresentation)
    }

    private func trendBlock(_ content: TrendModuleContent) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(L("近几个月"))
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            CompactMonthBarChart(
                points: content.points,
                xStart: content.xStart,
                xEnd: content.xEnd,
                highlight: content.highlight
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.spokenLabel)
    }

    private var actions: some View {
        HStack(spacing: MeterSpacing.xs) {
            Button(L("刷新用量")) {
                Task { await dashboard.refresh() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(dashboard.isRefreshing)
            if dashboard.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
            Spacer(minLength: 0)
            Button(L("退出 TollCat"), action: onQuit)
                .keyboardShortcut("q", modifiers: .command)
            Button(L("打开 TollCat"), action: onOpenMainWindow)
                .keyboardShortcut(.defaultAction)
        }
        .controlSize(.small)
    }
}

#Preview("Light") {
    MenuBarMeterView(dashboard: .preview, onOpenMainWindow: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MenuBarMeterView(dashboard: .preview, onOpenMainWindow: {})
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    MenuBarMeterView(dashboard: .previewEmpty, onOpenMainWindow: {})
}
