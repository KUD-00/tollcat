import Foundation
import SwiftData
import MeterCore

/// 手动订阅。续订提醒、涨价历史、logo 都不属于这个 App——这里只回答
/// 「这笔钱从哪个月开始算、到哪个月为止」。
///
/// `anchorDate` 不能按瞬时存。折算用传入的 `calendar` 取月和日；若把
/// 「本地 8/31 23:30」存成 UTC 零点，另一边用本地日历读，会变成 9/1，
/// 年付就会错一整年。所以这里存年/月/日三个日历分量，重建时必须用
/// **同一套 calendar**，并落到当天 12:00，避开夏令时和午夜边界。
@Model
public final class SubscriptionRecord {
    public var name: String
    public var amountUSD: Decimal
    public var periodRaw: String
    public var anchorYear: Int
    public var anchorMonth: Int
    public var anchorDay: Int
    /// 退订那个月。三个都是 nil = 还在付。可选而不是哨兵值：老行天然是 nil，
    /// 走轻量迁移，和 `quantity` 同一条路。存法与 anchor 一致（年/月/日三分量，
    /// 重建时落当天 12:00），不然「本地 8/31 23:30」在另一套日历里会漂成 9/1。
    public var endYear: Int?
    public var endMonth: Int?
    public var endDay: Int?
    public var accountIDRaw: String?
    public var providerIDRaw: String?
    /// 可选而不是带默认值的 Int：数量是后加的字段，可选才能走轻量迁移。
    /// 老行是 nil，读出来按 1 份算。
    public var quantity: Int?

    public init(domain: MonthlySubscription, calendar: Calendar) {
        self.name = domain.name
        self.amountUSD = 0
        self.periodRaw = ""
        self.anchorYear = 0
        self.anchorMonth = 0
        self.anchorDay = 0
        apply(domain: domain, calendar: calendar)
    }

    public func apply(domain: MonthlySubscription, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: domain.anchorDate)
        name = domain.name
        amountUSD = domain.amount.usd
        periodRaw = domain.period.rawValue
        anchorYear = components.year ?? 0
        anchorMonth = components.month ?? 0
        anchorDay = components.day ?? 0
        let end = domain.endDate.map { calendar.dateComponents([.year, .month, .day], from: $0) }
        endYear = end?.year
        endMonth = end?.month
        endDay = end?.day
        accountIDRaw = domain.accountID?.rawValue.uuidString
        providerIDRaw = domain.providerID?.rawValue
        quantity = domain.quantity
    }

    public func toDomain(calendar: Calendar) throws -> MonthlySubscription {
        guard let period = SubscriptionPeriod(rawValue: periodRaw) else {
            throw PersistenceError.invalidStoredPeriod(periodRaw)
        }
        var components = DateComponents()
        components.year = anchorYear
        components.month = anchorMonth
        components.day = anchorDay
        components.hour = 12
        guard let anchorDate = calendar.date(from: components) else {
            throw PersistenceError.invalidAnchorDate(
                year: anchorYear,
                month: anchorMonth,
                day: anchorDay
            )
        }
        return MonthlySubscription(
            name: name,
            amount: Money(usd: amountUSD),
            period: period,
            anchorDate: anchorDate,
            endDate: Self.endDate(
                year: endYear,
                month: endMonth,
                day: endDay,
                calendar: calendar
            ),
            accountID: accountIDRaw.flatMap(UUID.init(uuidString:)).map(AccountID.init(rawValue:)),
            providerID: providerIDRaw.map(ProviderID.init(rawValue:)),
            quantity: quantity ?? 1
        )
    }

    /// 三个分量缺一就是「没结束」。半条记录不该猜成某个日期。
    static func endDate(year: Int?, month: Int?, day: Int?, calendar: Calendar) -> Date? {
        guard let year, let month, let day else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)
    }
}
