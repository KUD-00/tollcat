import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

/// 日历热力图的追查页：有读数的每个月各一节，最近的在最上面。
///
/// 卡上只画得下一个月，翻月又只剩横扫（整块是链接，按钮收不到点按）。
/// 所以「别的月份长什么样」全落在这一页——键盘、读屏和 Mac 上翻月也走这里。
struct HeatmapDetailView: View {
    let content: HeatmapModuleContent

    @Environment(\.moneyPresentation) private var moneyPresentation

    var body: some View {
        MeterGroupedList {
            ForEach(content.months.reversed()) { month in
                Section {
                    grid(month)
                    totalRow(month)
                    ForEach(topDays(month), id: \.day) { entry in
                        dayRow(entry)
                    }
                } header: {
                    Text(month.title)
                }
            }
        }
        .navigationTitle(L("日历热力图"))
        .navigationBarTitleDisplayMode(.large)
    }

    /// 格子图本身不读给读屏（它是同一份数字的另一种画法），整节的话由合计那行说。
    private func grid(_ month: HeatmapMonth) -> some View {
        SpendHeatmapGrid(
            values: month.values,
            leadingEmptyDays: month.leadingEmptyDays,
            maxValue: month.maxValue
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowSeparator(.hidden)
        .accessibilityHidden(true)
    }

    private func totalRow(_ month: HeatmapMonth) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            Text(L("合计"))
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
            Spacer(minLength: MeterSpacing.xs)
            Text(month.totalText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
        }
        .meterListRowHitTarget()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("\(month.title) 共 \(month.spokenTotal)"))
    }

    private func dayRow(_ entry: DayEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MeterSpacing.xs) {
            Text(entry.dateText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterLabel)
            Spacer(minLength: MeterSpacing.xs)
            Text(entry.amountText)
                .font(MeterFont.body)
                .foregroundStyle(Color.meterSecondaryLabel)
                .monospacedDigit()
        }
        .meterListRowHitTarget()
    }

    /// 这个月花得最多的几天。整月 31 行读不动，也没人真去数第 17 天花了多少——
    /// 深浅看图，具体数字只有排在前面的几天值得写出来。
    ///
    /// 日期的写法**不在这里算**。这一页拿不到注入的那本日历，用 `Calendar.current`
    /// 加 `Date.formatted` 会按系统时区排字：折算按注入日历切的月，展示按系统时区
    /// 印的日，月末那一天会印成下个月 1 号。写法在 `HeatmapBuilder` 里就排好了。
    private func topDays(_ month: HeatmapMonth) -> [DayEntry] {
        month.values.enumerated()
            .compactMap { index, value -> (day: Int, amount: Money)? in
                guard let value, value > 0 else { return nil }
                return (index, Money(usd: Decimal(value)))
            }
            .sorted { $0.amount.usd > $1.amount.usd }
            .prefix(Self.topDayLimit)
            .map { entry in
                DayEntry(
                    day: entry.day,
                    dateText: month.dayLabel(at: entry.day),
                    amountText: entry.amount.formatted(using: moneyPresentation)
                )
            }
    }

    private static let topDayLimit = 5

    private struct DayEntry {
        var day: Int
        var dateText: String
        var amountText: String
    }
}

#Preview("Light") {
    NavigationStack {
        HeatmapDetailView(content: HeatmapPreviewData.sample)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        HeatmapDetailView(content: HeatmapPreviewData.sample)
    }
    .preferredColorScheme(.dark)
}
