import Foundation

/// 某个月的手填用量。金额用十进制字符串，避开 JSON number 丢精度。
///
/// 手填刷不回来，所以进迁移；API / 信箱缓存仍不装。
public struct TransferManualUsage: Codable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var periodYear: Int
    public var periodMonth: Int
    public var amountUSD: String
    public var enteredAt: Date
    /// 这笔手填在源设备上折成哪一种 kind。旧包没有这一键，按 `.usage` 读——
    /// 那正是旧包写死的那一个，所以老包导进来的行为一个字都不变。
    ///
    /// 带着走而不是到了新设备再查目录：目的地的目录版本可能不一样，
    /// 同一条记录在两台机器上算出不同的钱正是这一列要防的事。
    public var kindRaw: String

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        periodYear: Int,
        periodMonth: Int,
        amount: Money,
        enteredAt: Date,
        kind: ProviderKind
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.periodYear = periodYear
        self.periodMonth = periodMonth
        self.amountUSD = NSDecimalNumber(decimal: amount.usd).stringValue
        self.enteredAt = enteredAt
        self.kindRaw = kind.manualEntryKind.rawValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountID = try container.decode(AccountID.self, forKey: .accountID)
        providerID = try container.decode(ProviderID.self, forKey: .providerID)
        periodYear = try container.decode(Int.self, forKey: .periodYear)
        periodMonth = try container.decode(Int.self, forKey: .periodMonth)
        amountUSD = try container.decode(String.self, forKey: .amountUSD)
        enteredAt = try container.decode(Date.self, forKey: .enteredAt)
        kindRaw = try container.decodeIfPresent(String.self, forKey: .kindRaw)
            ?? ProviderKind.usage.rawValue
    }

    /// 解不出返回 nil，导入方整包拒绝——「读不懂」不能变成 $0 继续跑。
    public var money: Money? {
        Decimal(string: amountUSD).map { Money(usd: $0) }
    }
}
