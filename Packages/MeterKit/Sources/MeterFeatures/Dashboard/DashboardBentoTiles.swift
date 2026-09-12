import SwiftUI
import MeterDesign
import MeterModules

/// 构成卡下面那两张方卡。宽卡已经回答「钱在哪」；这两张只补充时间和对比。
/// 较上月同期点整张卡推进对比页；近几个月不是追查入口。
///
/// 并排时各占一半、高度跟较高那张齐。不要用 `aspectRatio` 去「变方」——
/// List 给的高度是无限的，比例约束会让两张按内容自己长，看起来一高一矮、
/// 又吃不满构成卡的宽。
struct DashboardBentoTiles: View {
    var comparison: ComparisonModuleContent?
    var trend: TrendModuleContent?
    var onOpenComparison: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: MeterSpacing.sm) {
                    tiles
                }
            } else {
                HStack(alignment: .top, spacing: MeterSpacing.sm) {
                    tiles
                }
                // 高度先按内容较高那张量，再回填给两张。List 给的高度是无限的，
                // 没有这一步，maxHeight: .infinity 不会把矮的那张撑开。
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func comparisonTile(_ comparison: ComparisonModuleContent) -> some View {
        let tile = ComparisonTileView(
            content: comparison,
            showsDisclosure: onOpenComparison != nil
        )
        if let onOpenComparison {
            Button(action: onOpenComparison) {
                tile.meterListRowHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("查看较上月同期明细"))
        } else {
            tile
        }
    }

    @ViewBuilder
    private var tiles: some View {
        if let comparison {
            comparisonTile(comparison)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        if let trend {
            TrendTileView(content: trend)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

#Preview("Light") {
    DashboardBentoTiles(
        comparison: DashboardBentoPreview.comparison,
        trend: DashboardBentoPreview.trend
    )
    .padding(.horizontal, MeterSpacing.pageHorizontal)
    .padding(.vertical, MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    DashboardBentoTiles(
        comparison: DashboardBentoPreview.comparison,
        trend: DashboardBentoPreview.trend
    )
    .padding(.horizontal, MeterSpacing.pageHorizontal)
    .padding(.vertical, MeterSpacing.md)
    .background(Color.meterGroupedBackground)
    .preferredColorScheme(.dark)
}

private enum DashboardBentoPreview {
    static let caption = String(localized: L("对比 \("7 月")同期 \("$58.40")"))
    static let comparison = ComparisonModuleContent(
        percentText: "-88%",
        caption: caption,
        spokenLabel: String(localized: L("按量较上月同期 \(DashboardPercentFormat.spokenSigned(-0.88))，\(caption)")),
        current: 7.16,
        previous: 58.40,
        currentLabel: String(localized: L("本月")),
        previousLabel: String(localized: L("上月")),
        tone: .down
    )

    static let trend: TrendModuleContent = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let lastMonth = Date(timeIntervalSince1970: 1_787_616_000)
        let start = calendar.date(byAdding: .month, value: -5, to: lastMonth) ?? lastMonth
        let points: [PlotPoint] = [12, 18, 9, 22, 15, 21].enumerated().compactMap { index, amount in
            calendar.date(byAdding: .month, value: index, to: start).map {
                PlotPoint(date: $0, amount: Double(amount))
            }
        }
        return TrendModuleContent(
            points: points,
            xStart: start,
            xEnd: CompactMonthBarChart.domainEnd(afterLastMonthStart: lastMonth, calendar: calendar),
            highlight: lastMonth,
            spokenLabel: String(localized: L("近几个月按量"))
        )
    }()
}
