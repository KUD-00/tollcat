#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterFormat
import MeterModules

/// 月格拖选 vs 两行 chip：同一个问题的两种答案，摆在一起看。
///
/// 筛选面板现在用的是两行 chip（哪个月 / 多长一段）加一层折叠的自定义区间。
/// 月格是另一条路：把两者合成一个平面，点一格是一个月，横拖是一段。
///
/// **要判断的是这三件事**：
/// - 「能拖」这件事第一次用看不看得出来。格子上没有把手，也没有提示。
/// - 一屏里 12 个格子和两行 chip，哪个更快找到「七月」。
/// - 空月份（灰的那几个）夹在区间中间时，读起来是不是仍然诚实。
struct GalleryMonthRangeView: View {
    @State private var selection = MonthWindow(newestBack: 0, oldestBack: 2)
    @State private var chipSelection = DashboardPeriod.currentMonth

    private let calendar = Calendar.current
    private let now = Date()

    /// 手上「有数」的月份。故意留两个洞（往前第 4、第 7 个月），
    /// 好看看区间跨过空月份时是什么样。
    private let monthsWithoutData: Set<Int> = [4, 7]

    var body: some View {
        MeterGroupedList {
            Section {
                VStack(alignment: .leading, spacing: MeterSpacing.xs) {
                    gridCaption(gridSpanCaption)
                    MonthRangeGrid(months: months, selection: $selection)
                }
                    .listRowInsets(EdgeInsets(
                        top: MeterSpacing.sm,
                        leading: MeterSpacing.md,
                        bottom: MeterSpacing.sm,
                        trailing: MeterSpacing.md
                    ))
                LabeledContent(L("选中")) {
                    Text(rangeTitle)
                        .foregroundStyle(Color.accentColor)
                }
                LabeledContent(L("跨度")) {
                    Text(L("\(selection.monthCount) 个月"))
                }
            } header: {
                Text(L("月格拖选"))
            } footer: {
                Text(L("点一格选一个月，按住横拖选一段。灰的月份没有读数，不能当区间的端点，但可以被夹在中间。VoiceOver 下每格有「设为起点 / 设为终点」两个动作。"))
            }

            Section {
                MeterSelectionChipRow {
                    ForEach(months.reversed()) { month in
                        MeterSelectionChip(
                            title: month.title,
                            isSelected: chipSelection == .months(back: month.monthsBack, count: 1)
                        ) {
                            chipSelection = .months(back: month.monthsBack, count: 1)
                        }
                    }
                }
                MeterSelectionChipRow {
                    ForEach(spanPresets, id: \.id) { preset in
                        MeterSelectionChip(
                            title: preset.title,
                            isSelected: chipSelection == preset.period
                        ) {
                            chipSelection = preset.period
                        }
                    }
                }
                LabeledContent(L("选中")) {
                    Text(chipTitle)
                        .foregroundStyle(Color.accentColor)
                }
            } header: {
                Text(L("两行 chip（正式页面现在用的）"))
            } footer: {
                Text(L("一行回答「哪个月」，一行回答「多长一段」，语义不重叠，所以永远只有一颗亮。跨月的自定义区间（五月–七月）在正式页面里收在下面一层折叠里，这里没铺。"))
            }

            Section {
                sample(L("单月"), window: MonthWindow(newestBack: 0, oldestBack: 0))
                sample(L("近 3 个月"), window: MonthWindow(newestBack: 0, oldestBack: 2))
                sample(L("跨行的一段"), window: MonthWindow(newestBack: 1, oldestBack: 6))
                sample(L("全期间"), window: MonthWindow(newestBack: 0, oldestBack: DashboardPeriod.maxMonthsBack))
            } header: {
                Text(L("几种区间的样子"))
            } footer: {
                Text(L("区间在一行里连成一条，行首行尾切平——每格各画一个胶囊的话，选中 6 个月看起来像选了 6 次。"))
            }
        }
        .navigationTitle(L("月份区间"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sample(_ title: LocalizedStringResource, window: MonthWindow) -> some View {
        VStack(alignment: .leading, spacing: MeterSpacing.xs) {
            Text(title)
                .font(MeterFont.footnote)
                .foregroundStyle(Color.meterSecondaryLabel)
            MonthRangeGrid(months: months, selection: .constant(window))
                .allowsHitTesting(false)
        }
        .listRowInsets(EdgeInsets(
            top: MeterSpacing.sm,
            leading: MeterSpacing.md,
            bottom: MeterSpacing.sm,
            trailing: MeterSpacing.md
        ))
    }

    // MARK: - 样例数据

    private var months: [MonthRangeGrid.Month] {
        (0...DashboardPeriod.maxMonthsBack).reversed().map { back in
            MonthRangeGrid.Month(
                monthsBack: back,
                title: MeterDateFormat.monthName(now: monthStart(back: back), calendar: calendar),
                hasData: !monthsWithoutData.contains(back)
            )
        }
    }

    /// 网格跨了哪两年写在上面这一行，不塞进格子里。
    private var gridSpanCaption: String {
        MeterDateFormat.monthRange(
            from: monthStart(back: DashboardPeriod.maxMonthsBack),
            to: monthStart(back: 0),
            calendar: calendar
        )
    }

    private func gridCaption(_ text: String) -> some View {
        Text(text)
            .font(MeterFont.footnote)
            .foregroundStyle(Color.meterSecondaryLabel)
    }

    /// 标题走 `DashboardFilterSummary` 那一处，不在画廊里另写一份中文——
    /// 画廊要对照的是版式，不是让同一句话在仓库里有第二个出处。
    private var spanPresets: [(id: String, title: String, period: DashboardPeriod)] {
        [
            (id: "3", period: DashboardPeriod.months(back: 0, count: 3)),
            (id: "6", period: DashboardPeriod.months(back: 0, count: 6)),
            (id: "ytd", period: DashboardPeriod.yearToDate),
            (id: "all", period: DashboardPeriod.allTime),
        ].map { (id: $0.id, title: title(for: $0.period), period: $0.period) }
    }

    private func title(for period: DashboardPeriod) -> String {
        DashboardFilterSummary.periodTitle(
            period: period,
            window: period.window(now: now, calendar: calendar),
            asOf: period.anchor(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var rangeTitle: String {
        let period = DashboardPeriod.months(
            back: selection.newestBack,
            count: selection.monthCount
        )
        return DashboardFilterSummary.periodTitle(
            period: period,
            window: selection,
            asOf: period.anchor(now: now, calendar: calendar),
            calendar: calendar
        )
    }

    private var chipTitle: String { title(for: chipSelection) }

    private func monthStart(back: Int) -> Date {
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let target = calendar.date(byAdding: .month, value: -back, to: thisMonthStart)
        else {
            return now
        }
        return target
    }
}

#Preview("Light") {
    NavigationStack {
        GalleryMonthRangeView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryMonthRangeView()
    }
    .preferredColorScheme(.dark)
}
#endif
