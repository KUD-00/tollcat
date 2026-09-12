import Foundation
import Foundation
import SwiftUI
import Testing
@testable import MeterDesign

struct ChartMoneyScaleTests {
    @Test("Y 轴用整美元，覆盖最大值")
    func marksCoverMaximum() {
        let marks = ChartMoneyScale.marks(max: 21.4)
        #expect(marks.first == 0)
        #expect(marks.last ?? 0 >= 21.4)
        #expect(marks.count >= 2)
        #expect(ChartMoneyScale.label(0) == "$0")
        #expect(ChartMoneyScale.label(20) == "$20")
    }

    @Test("全 0 也有刻度")
    func zeroHasScale() {
        let marks = ChartMoneyScale.marks(max: 0)
        #expect(marks.first == 0)
        #expect(marks.last ?? 0 > 0)
    }

    @Test("按住读数看分位")
    func detailLabelKeepsCents() {
        #expect(ChartMoneyScale.detailLabel(2.2) == "$2.20")
        #expect(ChartMoneyScale.detailLabel(0) == "$0.00")
    }
}

struct ChartInspectionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("柱：落在有读数的那天就报那天的金额")
    func spendHitsABar() {
        let hit = ChartInspection.spend(
            raw: date(3),
            points: points,
            unit: .day,
            calendar: calendar
        )
        #expect(hit?.amount == 2.2)
        #expect(hit.map { calendar.isDate($0.date, inSameDayAs: date(3)) } == true)
    }

    @Test("柱：缺的那天是无数据，不滑去旁边的柱")
    func spendGapIsMissingNotNeighbor() {
        let gap = ChartInspection.spend(
            raw: date(4),
            points: points,
            unit: .day,
            calendar: calendar
        )
        #expect(gap?.amount == nil)
        #expect(gap.map { calendar.isDate($0.date, inSameDayAs: date(4)) } == true)
    }

    @Test("余额：对准最近一次实测，不编虚线上的插值")
    func balanceSnapsToNearestReading() {
        let raw = calendar.date(byAdding: .day, value: 2, to: date(1))!
        let hit = ChartInspection.balance(
            raw: raw,
            points: [
                PlotPoint(date: date(1), amount: 50),
                PlotPoint(date: date(9), amount: 40),
            ],
            unit: .day,
            calendar: calendar
        )
        #expect(hit?.amount == 50)
        #expect(hit.map { calendar.isDate($0.date, inSameDayAs: date(1)) } == true)
    }

    private var points: [PlotPoint] {
        [
            PlotPoint(date: date(1), amount: 0.5),
            PlotPoint(date: date(3), amount: 2.2),
            PlotPoint(date: date(6), amount: 2.2),
        ]
    }

    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: day))!
    }
}

struct CompactMonthBarDomainTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("横轴右端是本月的下月 1 号，本月柱才落在图里")
    func domainEndIsTheNextMonthStart() {
        let august = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let end = CompactMonthBarChart.domainEnd(afterLastMonthStart: august, calendar: calendar)
        #expect(calendar.component(.month, from: end) == 9)
        #expect(calendar.component(.day, from: end) == 1)
        #expect(end > august)
    }

    @Test("每个整月一个标签，不含横轴右端那个没有柱的月")
    func monthLabelsCoverEachBarNotTheDomainEnd() {
        let march = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let september = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        let labels = CompactMonthBarChart.monthLabels(from: march, to: september, calendar: calendar)
        #expect(labels.count == 6)
        #expect(labels.map { calendar.component(.month, from: $0) } == [3, 4, 5, 6, 7, 8])
        #expect(labels.allSatisfy { $0 >= march && $0 < september })
    }

    @Test("跨年也按月连续标")
    func monthLabelsCrossYear() {
        let november = calendar.date(from: DateComponents(year: 2025, month: 11, day: 1))!
        let february = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let labels = CompactMonthBarChart.monthLabels(from: november, to: february, calendar: calendar)
        #expect(labels.map { calendar.component(.month, from: $0) } == [11, 12, 1])
        #expect(calendar.component(.year, from: labels[0]) == 2025)
        #expect(calendar.component(.year, from: labels[2]) == 2026)
    }

    @Test("只有一个月时标那一根")
    func monthLabelsSingleMonth() {
        let august = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let september = CompactMonthBarChart.domainEnd(afterLastMonthStart: august, calendar: calendar)
        #expect(CompactMonthBarChart.monthLabels(from: august, to: september, calendar: calendar) == [august])
    }

    @Test("12 个月窗标满 12 个整月")
    func monthLabelsCoverAYear() {
        let september = calendar.date(from: DateComponents(year: 2025, month: 9, day: 1))!
        let nextSeptember = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        let labels = CompactMonthBarChart.monthLabels(from: september, to: nextSeptember, calendar: calendar)
        #expect(labels.count == 12)
        #expect(calendar.component(.month, from: labels[0]) == 9)
        #expect(calendar.component(.month, from: labels[11]) == 8)
    }
}

struct DailySpendChartDomainTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("日柱右端是最后一天的次日零点，当天柱才落在图里")
    func dayDomainEndIsNextDayStart() {
        let last = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let end = DailySpendChart.domainEnd(afterLastPeriodStart: last, unit: .day, calendar: calendar)
        let next = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
        #expect(end == next)
        #expect(end > last)
    }

    @Test("月柱右端是下月 1 号，月中的 xEnd 先归到当月 1 号")
    func monthDomainEndBucketsThenAdvances() {
        let mid = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let end = DailySpendChart.domainEnd(afterLastPeriodStart: mid, unit: .month, calendar: calendar)
        #expect(calendar.component(.year, from: end) == 2026)
        #expect(calendar.component(.month, from: end) == 9)
        #expect(calendar.component(.day, from: end) == 1)
        #expect(end > mid)
    }

    @Test("12 个月窗最后一根柱的右沿等于横轴右端")
    func lastMonthBarEndsAtPlotEnd() {
        let monthStart = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let today = calendar.date(from: DateComponents(year: 2026, month: 8, day: 16))!
        let plotEnd = DailySpendChart.domainEnd(afterLastPeriodStart: today, unit: .month, calendar: calendar)
        let barEnd = DailySpendChart.domainEnd(afterLastPeriodStart: monthStart, unit: .month, calendar: calendar)
        #expect(barEnd == plotEnd)
    }
}

struct CompositionDonutSelectionTests {
    private let slices = [
        CompositionDonut.Slice(id: "aws", color: .blue, fraction: 0.5, name: "AWS", amountText: "$21.40"),
        CompositionDonut.Slice(id: "cf", color: .orange, fraction: 0.3, name: "Cloudflare", amountText: "$11.05"),
        CompositionDonut.Slice(id: "oa", color: .green, fraction: 0.2, name: "OpenAI", amountText: "$7.62"),
    ]

    @Test("角度按绘制值的前缀和落段，段边界归前一段")
    func angleFallsIntoCumulativeBucket() {
        #expect(CompositionDonut.slice(at: 0.0, slices: slices, reveal: 1)?.id == "aws")
        #expect(CompositionDonut.slice(at: 0.49, slices: slices, reveal: 1)?.id == "aws")
        #expect(CompositionDonut.slice(at: 0.5, slices: slices, reveal: 1)?.id == "aws")
        #expect(CompositionDonut.slice(at: 0.51, slices: slices, reveal: 1)?.id == "cf")
        #expect(CompositionDonut.slice(at: 0.99, slices: slices, reveal: 1)?.id == "oa")
    }

    @Test("进场半途（reveal < 1）时映射跟着缩放走，不落错段")
    func mappingScalesWithReveal() {
        #expect(CompositionDonut.slice(at: 0.2, slices: slices, reveal: 0.5)?.id == "aws")
        #expect(CompositionDonut.slice(at: 0.3, slices: slices, reveal: 0.5)?.id == "cf")
        #expect(CompositionDonut.slice(at: 0.45, slices: slices, reveal: 0.5)?.id == "oa")
    }

    @Test("负角度和超出总和的角度不命中")
    func outOfRangeMisses() {
        #expect(CompositionDonut.slice(at: -0.1, slices: slices, reveal: 1) == nil)
        #expect(CompositionDonut.slice(at: 1.5, slices: slices, reveal: 1) == nil)
    }
}
