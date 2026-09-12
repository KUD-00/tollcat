import Foundation

/// 手动订阅。金额用十进制字符串，避开 JSON number 丢精度。
public struct TransferSubscription: Codable, Equatable, Sendable {
    public var name: String
    public var amountUSD: String
    public var period: SubscriptionPeriod
    public var anchorYear: Int
    public var anchorMonth: Int
    public var anchorDay: Int
    /// 退订那个月。三个都缺 = 还在付。
    public var endYear: Int?
    public var endMonth: Int?
    public var endDay: Int?
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var quantity: Int

    public init(
        name: String,
        amount: Money,
        period: SubscriptionPeriod,
        anchorYear: Int,
        anchorMonth: Int,
        anchorDay: Int,
        endYear: Int? = nil,
        endMonth: Int? = nil,
        endDay: Int? = nil,
        accountID: AccountID? = nil,
        providerID: ProviderID?,
        quantity: Int = 1
    ) {
        self.name = name
        self.amountUSD = NSDecimalNumber(decimal: amount.usd).stringValue
        self.period = period
        self.anchorYear = anchorYear
        self.anchorMonth = anchorMonth
        self.anchorDay = anchorDay
        self.endYear = endYear
        self.endMonth = endMonth
        self.endDay = endDay
        self.accountID = accountID
        self.providerID = providerID
        self.quantity = quantity
    }

    /// 解不出返回 nil，导入方整包拒绝——「读不懂」不能变成 $0 继续跑。
    public var money: Money? {
        Decimal(string: amountUSD).map { Money(usd: $0) }
    }

    public func anchorDate(calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.year = anchorYear
        components.month = anchorMonth
        components.day = anchorDay
        components.hour = 12
        return calendar.date(from: components)
    }

    /// 缺任一分量都算「还在付」。半条记录不猜日期。
    public func endDate(calendar: Calendar) -> Date? {
        guard let endYear, let endMonth, let endDay else { return nil }
        var components = DateComponents()
        components.year = endYear
        components.month = endMonth
        components.day = endDay
        components.hour = 12
        return calendar.date(from: components)
    }
}
