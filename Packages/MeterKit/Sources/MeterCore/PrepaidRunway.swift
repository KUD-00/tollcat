import Foundation

/// 预充值按近 7 日均速还能撑多久。没有足够历史时不算这条。
public struct PrepaidRunway: Hashable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var balanceUSD: Money
    public var averageDailyUSD: Money
    public var daysRemaining: Int

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        balanceUSD: Money,
        averageDailyUSD: Money,
        daysRemaining: Int
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.balanceUSD = balanceUSD
        self.averageDailyUSD = averageDailyUSD
        self.daysRemaining = daysRemaining
    }
}
