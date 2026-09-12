import Foundation
import SwiftData
import MeterCore

/// 每个用量身份每个月留最新一条给迁移。同月历次填写在 SnapshotRecord，这里不存同月历史。
@Model
public final class ManualUsageRecord {
    public var accountIDRaw: String
    public var providerIDRaw: String
    public var periodYear: Int
    public var periodMonth: Int
    public var amountUSD: Decimal
    public var enteredAt: Date
    /// 这笔手填折成快照时用哪一种 kind。可选走轻量迁移，老行读出来按 `.usage`。
    ///
    /// **不在读的时候现查目录**：`MeterPersistence` 不认识 provider 目录，
    /// 而迁移导入这条路曾经因此写死 `.usage`，同一条记录在两台设备上算出不同的钱。
    /// 存下来之后「这笔手填算哪一种」只有一个出处，导出导入原样带走。
    /// 值域由 `ProviderKind.manualEntryKind` 收口（只可能是 `.usage` / `.planAndUsage`）。
    public var kindRaw: String?

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        periodYear: Int,
        periodMonth: Int,
        amount: Money,
        enteredAt: Date,
        kind: ProviderKind
    ) {
        self.accountIDRaw = accountID.rawValue.uuidString
        self.providerIDRaw = providerID.rawValue
        self.periodYear = periodYear
        self.periodMonth = periodMonth
        self.amountUSD = amount.usd
        self.enteredAt = enteredAt
        self.kindRaw = kind.manualEntryKind.rawValue
    }

    /// 老行（没有这一列）按 `.usage` 读。手填只有 `currentSpendUSD` 一格，
    /// `.usage` 是它永远装得下的那一种。
    public var kind: ProviderKind {
        (kindRaw.flatMap(ProviderKind.init(rawValue:)) ?? .usage).manualEntryKind
    }

    /// 解不出就抛，与 `SnapshotRecord.toDomain` 同一口径。全零回退会和
    /// 测试夹具 `fixture(0)` 撞车，还让坏行伪装成一份真账号。
    public func domainAccountID() throws -> AccountID {
        guard let uuid = UUID(uuidString: accountIDRaw) else {
            throw PersistenceError.invalidStoredAccount(accountIDRaw)
        }
        return AccountID(rawValue: uuid)
    }

    public var providerID: ProviderID {
        ProviderID(providerIDRaw)
    }

    public var amount: Money {
        Money(usd: amountUSD)
    }

    public func apply(
        periodYear: Int,
        periodMonth: Int,
        amount: Money,
        enteredAt: Date,
        kind: ProviderKind
    ) {
        self.periodYear = periodYear
        self.periodMonth = periodMonth
        self.amountUSD = amount.usd
        self.enteredAt = enteredAt
        self.kindRaw = kind.manualEntryKind.rawValue
    }

    public func transferItem() throws -> TransferManualUsage {
        TransferManualUsage(
            accountID: try domainAccountID(),
            providerID: providerID,
            periodYear: periodYear,
            periodMonth: periodMonth,
            amount: amount,
            enteredAt: enteredAt,
            kind: kind
        )
    }

    /// 折成快照。**kind 从这一行自己来**——调用方不再各自去猜。
    public func snapshot(calendar: Calendar) throws -> Snapshot {
        var components = DateComponents()
        components.year = periodYear
        components.month = periodMonth
        components.day = 1
        components.hour = 12
        let start = calendar.date(from: components) ?? enteredAt
        let next = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .day, value: -1, to: next) ?? start
        return Snapshot(
            providerID: providerID,
            accountID: try domainAccountID(),
            kind: kind,
            source: .manual,
            fetchedAt: enteredAt,
            periodStart: start,
            periodEnd: end,
            currentSpendUSD: amount
        )
    }
}
