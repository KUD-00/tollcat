import Foundation

/// 按住图表时要对准的那一格。
///
/// `amount == nil` 表示落在没有读数的那天/月——缺失，不是 $0。
public struct ChartInspection: Equatable, Sendable {
    public var date: Date
    public var amount: Double?

    public init(date: Date, amount: Double?) {
        self.date = date
        self.amount = amount
    }

    /// 柱：对准那一格。格子里没柱就是无数据，不滑去旁边那天。
    public static func spend(
        raw: Date?,
        points: [PlotPoint],
        unit: ChartTimeUnit,
        calendar: Calendar
    ) -> ChartInspection? {
        guard let raw else { return nil }
        let bucket = unit.bucket(raw, calendar: calendar)
        if let hit = points.first(where: { unit.bucket($0.date, calendar: calendar) == bucket }) {
            return ChartInspection(date: unit.bucket(hit.date, calendar: calendar), amount: hit.amount)
        }
        return ChartInspection(date: bucket, amount: nil)
    }

    /// 余额：对准最近一次实测。虚线中间没有读数，不编一个插值。
    public static func balance(
        raw: Date?,
        points: [PlotPoint],
        unit: ChartTimeUnit,
        calendar: Calendar
    ) -> ChartInspection? {
        guard let raw, !points.isEmpty else { return nil }
        let nearest = points.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(raw)) < abs(rhs.date.timeIntervalSince(raw))
        }!
        return ChartInspection(
            date: unit.bucket(nearest.date, calendar: calendar),
            amount: nearest.amount
        )
    }
}

extension ChartTimeUnit {
    func bucket(_ date: Date, calendar: Calendar) -> Date {
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date))
                ?? calendar.startOfDay(for: date)
        }
    }
}
