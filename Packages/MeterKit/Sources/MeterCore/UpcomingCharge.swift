import Foundation

/// 未来几天内会扣的一笔订阅。名称可能为空，展示层用 provider 名补。
public struct UpcomingCharge: Hashable, Sendable {
    public var name: String
    public var accountID: AccountID?
    public var providerID: ProviderID?
    public var amount: Money
    public var chargeDate: Date

    public init(
        name: String,
        accountID: AccountID? = nil,
        providerID: ProviderID?,
        amount: Money,
        chargeDate: Date
    ) {
        self.name = name
        self.accountID = accountID
        self.providerID = providerID
        self.amount = amount
        self.chargeDate = chargeDate
    }
}
