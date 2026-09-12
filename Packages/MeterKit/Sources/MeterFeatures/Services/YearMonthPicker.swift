import SwiftUI
import MeterDesign
import MeterFormat

/// SwiftUI `DatePicker` 没有年月。UIKit 的 `.yearAndMonth` 只支持滚轮，
/// 配 `.compact` 会直接断言崩溃；滚轮又太高，塞不进这张抽屉。
/// 年月是两档离散值，走系统 `Picker`。
struct YearMonthPicker: View {
    @Binding var selection: Date
    var calendar: Calendar
    var now: Date
    /// 闭区间。订阅开始时间不设，手填花费卡在 12 个月图能看见的范围。
    var lowerBound: Date? = nil
    var upperBound: Date? = nil

    var body: some View {
        HStack(spacing: MeterSpacing.xs) {
            if yearComesFirst {
                yearPicker
                monthPicker
            } else {
                monthPicker
                yearPicker
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var monthPicker: some View {
        Picker(selection: monthBinding) {
            ForEach(availableMonths(for: year), id: \.self) { month in
                Text(monthTitle(month)).tag(month)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var yearPicker: some View {
        Picker(selection: yearBinding) {
            ForEach(years, id: \.self) { year in
                Text(verbatim: String(year)).tag(year)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var year: Int { calendar.component(.year, from: selection) }
    private var month: Int { calendar.component(.month, from: selection) }

    /// 两侧的界各管各的。
    ///
    /// 以前这里要求**两个界都给**才生效，只给一个上界时年份仍然一路排到 +5——
    /// 而月份那一列被上界筛成空，于是能选到一个一个月都没有的年份。
    private var years: [Int] {
        let selectedYear = year
        let nowYear = calendar.component(.year, from: now)
        let lower = lowerBound.map { calendar.component(.year, from: $0) } ?? (nowYear - 20)
        let upper = upperBound.map { calendar.component(.year, from: $0) } ?? (nowYear + 5)
        return Array(min(lower, selectedYear)...max(upper, selectedYear))
    }

    private var yearBinding: Binding<Int> {
        Binding(
            get: { year },
            set: { newYear in
                selection = date(year: newYear, month: clampedMonth(newYear, month))
            }
        )
    }

    private var monthBinding: Binding<Int> {
        Binding(
            get: { month },
            set: { selection = date(year: year, month: clampedMonth(year, $0)) }
        )
    }

    private func availableMonths(for year: Int) -> [Int] {
        var months = Array(1...12)
        if let lowerBound {
            let boundYear = calendar.component(.year, from: lowerBound)
            let boundMonth = calendar.component(.month, from: lowerBound)
            if year < boundYear { return [] }
            if year == boundYear { months = months.filter { $0 >= boundMonth } }
        }
        if let upperBound {
            let boundYear = calendar.component(.year, from: upperBound)
            let boundMonth = calendar.component(.month, from: upperBound)
            if year > boundYear { return [] }
            if year == boundYear { months = months.filter { $0 <= boundMonth } }
        }
        return months
    }

    private func clampedMonth(_ year: Int, _ month: Int) -> Int {
        let allowed = availableMonths(for: year)
        if allowed.contains(month) { return month }
        return allowed.last ?? month
    }

    private var yearComesFirst: Bool {
        let format = DateFormatter.dateFormat(
            fromTemplate: "yMMMM",
            options: 0,
            locale: calendar.locale ?? .current
        ) ?? "yMMMM"
        guard
            let yearIndex = format.firstIndex(of: "y"),
            let monthIndex = format.firstIndex(of: "M")
        else {
            return true
        }
        return yearIndex < monthIndex
    }

    private func monthTitle(_ month: Int) -> String {
        var components = DateComponents()
        components.year = 2020
        components.month = month
        components.day = 1
        guard let date = calendar.date(from: components) else { return "\(month)" }
        return MeterDateFormat.monthName(now: date, calendar: calendar)
    }

    private func date(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 12
        return calendar.date(from: components) ?? selection
    }
}

#Preview("Light") {
    YearMonthPickerPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    YearMonthPickerPreview()
        .preferredColorScheme(.dark)
}

private struct YearMonthPickerPreview: View {
    @State private var date = Date()

    var body: some View {
        Form {
            HStack {
                Text(L("开始时间"))
                Spacer(minLength: MeterSpacing.sm)
                YearMonthPicker(selection: $date, calendar: .current, now: Date())
            }
        }
    }
}
