import SwiftUI
import MeterDesign

public struct TrendTileView: View {
    public let content: TrendModuleContent
    /// 手机方卡用默认的小柱；宽壳定高卡里给高一点，别让柱缩在卡底。
    public var plotHeight: CGFloat = MeterSpacing.bentoChart
    /// 宽壳定高卡有地方放「月均」大数字；手机方卡太小，只放柱。
    public var showsHeadline: Bool = false

    public init(
        content: TrendModuleContent,
        plotHeight: CGFloat = MeterSpacing.bentoChart,
        showsHeadline: Bool = false
    ) {
        self.content = content
        self.plotHeight = plotHeight
        self.showsHeadline = showsHeadline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(L("近几个月"))
                .font(MeterFont.caption)
                .foregroundStyle(Color.meterSecondaryLabel)
            // 月均只给数，不解释口径——「不含本月」是详情页的事，卡上多一行灰字
            // 只是把柱图往下挤。
            if showsHeadline, let average = content.averageText {
                DashboardCardHeadline(value: average)
            }
            Spacer(minLength: 0)
            CompactMonthBarChart(
                points: content.points,
                xStart: content.xStart,
                xEnd: content.xEnd,
                highlight: content.highlight,
                plotHeight: plotHeight
            )
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(MeterSpacing.md)
        .background(
            Color.meterSecondaryGroupedBackground,
            in: cardShape
        )
        .clipShape(cardShape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.spokenLabel)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MeterRadius.groupedCard, style: .continuous)
    }
}

#Preview("Light") {
    TrendTileView(content: TrendTilePreview.sample)
        .frame(width: 170, height: 170)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrendTileView(content: TrendTilePreview.sample)
        .frame(width: 170, height: 170)
        .preferredColorScheme(.dark)
}

private enum TrendTilePreview {
    static let sample: TrendModuleContent = {
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
