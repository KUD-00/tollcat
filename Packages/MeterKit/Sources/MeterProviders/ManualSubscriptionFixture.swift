import Foundation
import MeterCore

/// 手动订阅 fixture。扣款日用相对 `now` 的偏移，才能在设计时钟和别的月份都落在未来 7 天内。
struct ManualSubscriptionFixture: Decodable, Sendable {
    var name: String
    var amountUSD: Double
    var period: SubscriptionPeriod
    var daysUntilCharge: Int?
    var chargeDayOfMonth: Int?
    /// 往前挪几个月开始。只给「已经退掉」那种演示数据用——退订月必须在开始月之后。
    var startedMonthsAgo: Int?
    /// 几个月前退的。有值就是一笔历史订阅：本月计 0，过去那几个月照旧算数。
    var endedMonthsAgo: Int?
    var providerID: String?

    func materialize(now: Date, calendar: Calendar) -> MonthlySubscription? {
        guard var anchor = resolveAnchor(now: now, calendar: calendar) else { return nil }
        if let startedMonthsAgo {
            anchor = calendar.date(byAdding: .month, value: -startedMonthsAgo, to: anchor) ?? anchor
        }
        return MonthlySubscription(
            name: name,
            amount: Money(roundedUSD: amountUSD),
            period: period,
            anchorDate: anchor,
            endDate: endedMonthsAgo.flatMap {
                calendar.date(byAdding: .month, value: -$0, to: now)
            },
            providerID: providerID.map(ProviderID.init(rawValue:))
        )
    }

    private func resolveAnchor(now: Date, calendar: Calendar) -> Date? {
        if let daysUntilCharge {
            guard let day = calendar.date(byAdding: .day, value: daysUntilCharge, to: calendar.startOfDay(for: now)) else {
                return nil
            }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = 12
            return calendar.date(from: components)
        }
        if let chargeDayOfMonth {
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 1
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = min(max(chargeDayOfMonth, 1), daysInMonth)
            components.hour = 12
            return calendar.date(from: components)
        }
        return nil
    }
}
