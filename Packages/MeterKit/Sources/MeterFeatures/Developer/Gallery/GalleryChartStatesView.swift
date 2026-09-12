#if DEBUG
import SwiftUI
import MeterDesign

struct GalleryChartStatesView: View {
    var body: some View {
        MeterGroupedList {
            Section {
                ProviderHistoryChartView(content: spendCycle[0])
            } header: {
                Text(L("还没有每日花费"))
            }
            Section {
                ProviderHistoryChartView(content: spendCycle[1])
            } header: {
                Text(L("一天"))
            }
            Section {
                ProviderHistoryChartView(content: spendCycle[2])
            } header: {
                Text(L("整月"))
            } footer: {
                Text(L("缺的那天留空，不要补 0。只有一根柱时也不该占满整图。按住柱子看那天的金额。"))
            }

            Section {
                ProviderHistoryChartView(
                    content: scrollSample,
                    visibleDayCount: 7
                )
            } header: {
                Text(L("滑动时间轴"))
            } footer: {
                Text(L("7 天和 30 天是看得见的宽度。图是一条时间轴：轻滑移一点，甩一下惯性滑过很多天。12 个月已经是整段，不滑。"))
            }

            Section {
                ProviderHistoryChartView(content: balanceCycle[0])
            } header: {
                Text(L("还没有余额记录"))
            }
            Section {
                ProviderHistoryChartView(content: balanceCycle[1])
            } header: {
                Text(L("一个点"))
            }
            Section {
                ProviderHistoryChartView(content: balanceCycle[2])
            } header: {
                Text(L("一条折线"))
            } footer: {
                Text(L("两个已知余额之间若有缺口，用虚线跨过去。虚线是推断，不是实测。按住折线看那一次的余额。"))
            }
        }
        .navigationTitle(L("图表"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var spendCycle: [ProviderHistoryChartContent] {
        [
            .spend(points: [], start: Self.start, end: Self.end, granularity: .day, isIntervalSpend: false),
            .spend(
                points: [PlotPoint(date: Self.start, amount: 2.2)],
                start: Self.start,
                end: Self.end,
                granularity: .day,
                isIntervalSpend: false
            ),
            .spend(points: Self.monthBars, start: Self.start, end: Self.end, granularity: .day, isIntervalSpend: false),
        ]
    }

    private var balanceCycle: [ProviderHistoryChartContent] {
        [
            .balance(
                points: [],
                start: Self.start,
                end: Self.end,
                granularity: .day,
                inferred: []
            ),
            .balance(
                points: [PlotPoint(date: Self.end, amount: 42)],
                start: Self.start,
                end: Self.end,
                granularity: .day,
                inferred: []
            ),
            .balance(
                points: [
                    PlotPoint(date: Self.start, amount: 49.62),
                    PlotPoint(date: Self.mid, amount: 58.33),
                    PlotPoint(date: Self.end, amount: 42),
                ],
                start: Self.start,
                end: Self.end,
                granularity: .day,
                inferred: [
                    PlotSegment(
                        start: PlotPoint(date: Self.start, amount: 49.62),
                        end: PlotPoint(date: Self.mid, amount: 58.33),
                        isInferred: true
                    ),
                    PlotSegment(
                        start: PlotPoint(date: Self.mid, amount: 58.33),
                        end: PlotPoint(date: Self.end, amount: 42),
                        isInferred: true
                    ),
                ]
            ),
        ]
    }

    private static let calendar = Calendar(identifier: .gregorian)
    private static let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
    private static let mid = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9))!
    private static let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!

    private static let monthBars: [PlotPoint] = (1...16).compactMap { day in
        if day == 4 || day == 5 { return nil }
        guard let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: day)) else {
            return nil
        }
        return PlotPoint(date: date, amount: day < 9 ? 0.5 : 2.2)
    }

    private var scrollSample: ProviderHistoryChartContent {
        .spend(
            points: Self.monthBars,
            start: Self.start,
            end: Self.end,
            granularity: .day,
            isIntervalSpend: false
        )
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryChartStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryChartStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
