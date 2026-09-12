import Charts
import SwiftUI

/// 日线图当前看得见的左端。平移时只把这个日期送上去写起止日，不要重建图。
public struct ChartVisibleStartPreference: PreferenceKey {
    public static var defaultValue: Date? { nil }

    public static func reduce(value: inout Date?, nextValue: () -> Date?) {
        value = nextValue() ?? value
    }
}

/// 7 / 30 天是看得见的宽度。时间轴用系统 Charts 的横滑，惯性白送。
struct MeterChartScrolling: ViewModifier {
    var visibleDayCount: Int?
    var xStart: Date
    var xEnd: Date
    @State private var leading: Date?
    @Environment(\.calendar) private var calendar

    func body(content: Content) -> some View {
        if let days = visibleDayCount, days > 0 {
            content
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleLength(days))
                .chartScrollPosition(x: scrollBinding(days))
                .scrollClipDisabled()
                .preference(key: ChartVisibleStartPreference.self, value: resolvedLeading(days))
                .onChange(of: visibleDayCount) { old, new in
                    if let old, let new {
                        keepTrailingEdge(from: old, to: new)
                    }
                }
        } else {
            content
        }
    }

    private func keepTrailingEdge(from old: Int, to new: Int) {
        let current = resolvedLeading(old)
        let trailing = calendar.date(byAdding: .day, value: old - 1, to: current) ?? current
        let next = calendar.date(byAdding: .day, value: 1 - new, to: trailing) ?? current
        leading = clamped(next, days: new)
    }

    private func scrollBinding(_ days: Int) -> Binding<Date> {
        Binding(
            get: { resolvedLeading(days) },
            set: { leading = clamped($0, days: days) }
        )
    }

    private func resolvedLeading(_ days: Int) -> Date {
        clamped(leading ?? defaultLeading(days), days: days)
    }

    private func defaultLeading(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: 1 - days, to: xEnd) ?? xStart
    }

    private func clamped(_ date: Date, days: Int) -> Date {
        let minLeading = xStart
        let maxLeading = defaultLeading(days)
        if date < minLeading { return minLeading }
        if date > maxLeading { return maxLeading }
        return date
    }

    private func visibleLength(_ days: Int) -> TimeInterval {
        let start = resolvedLeading(days)
        let end = calendar.date(byAdding: .day, value: days, to: start) ?? start
        return max(end.timeIntervalSince(start), 1)
    }
}
