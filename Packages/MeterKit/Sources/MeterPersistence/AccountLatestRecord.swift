import Foundation
import SwiftData
import MeterCore

/// 一个账号此刻状态的落库。**每账号一行。**
///
/// 和 `MonthlyRollupRecord` 一样是**缓存**：随时能整份删掉、从快照重折，
/// 所以不进迁移包、不需要任何数据迁移。
///
/// 它和月度账本的区别是**时态**不是粒度——余额、免费额度、下次扣款说的都是"现在"，
/// 折进按月的行会让回看七月时显示今天的余额。
@Model
public final class AccountLatestRecord {
    /// 每账号一行，取的时候永远按账号取。
    #Index<AccountLatestRecord>([\.accountIDRaw])

    public var accountIDRaw: String
    public var providerIDRaw: String
    public var kindRaw: String
    public var fetchedAt: Date
    public var sourceRaw: String = SnapshotSource.api.rawValue

    /// `Money` 按 `Decimal` 落库，和别的表同一条规矩。
    public var balanceUSD: Decimal?
    /// 那笔余额的原币说明。**两列标量**，不是把 `ConvertedAmount` 整个搬过来
    /// （见 `AccountLatest` 的准入准则第 4 条）。两列都 nil = 没换过币。
    /// 原币金额由 `balanceUSD ÷ balanceRate` 还原，不单独存第三列。
    public var balanceCurrency: String?
    public var balanceRate: Decimal?
    public var freeQuotaUsedRatio: Double?
    public var committedMonthlyUSD: Decimal?
    public var chargeDayOfMonth: Int?
    /// 这家自己报的账单金额。列表行金额的兜底。
    public var reportedAmountUSD: Decimal?
    /// 那笔金额记在哪个月。**手填的读数才有**（可能是给上个月补的）；
    /// API 读数永远是「此刻」，两列都是 nil。年和月分开存，理由同
    /// `SubscriptionRecord.anchorYear`：日历分量不能按瞬时落盘。
    public var reportedAmountYear: Int?
    public var reportedAmountMonth: Int?

    public init(domain: AccountLatest) {
        self.accountIDRaw = domain.accountID.rawValue.uuidString
        self.providerIDRaw = domain.providerID.rawValue
        self.kindRaw = domain.kind.rawValue
        self.fetchedAt = domain.fetchedAt
        self.sourceRaw = domain.source.rawValue
        self.balanceUSD = domain.balanceUSD?.usd
        self.balanceCurrency = domain.balanceOriginalCurrency
        self.balanceRate = domain.balanceUSDPerUnit
        self.freeQuotaUsedRatio = domain.freeQuotaUsedRatio
        self.committedMonthlyUSD = domain.committedMonthlyUSD?.usd
        self.chargeDayOfMonth = domain.chargeDayOfMonth
        self.reportedAmountUSD = domain.reportedAmountUSD?.usd
        self.reportedAmountYear = domain.reportedAmountMonth?.year
        self.reportedAmountMonth = domain.reportedAmountMonth?.month
    }

    public func apply(_ domain: AccountLatest) {
        providerIDRaw = domain.providerID.rawValue
        kindRaw = domain.kind.rawValue
        fetchedAt = domain.fetchedAt
        sourceRaw = domain.source.rawValue
        balanceUSD = domain.balanceUSD?.usd
        balanceCurrency = domain.balanceOriginalCurrency
        balanceRate = domain.balanceUSDPerUnit
        freeQuotaUsedRatio = domain.freeQuotaUsedRatio
        committedMonthlyUSD = domain.committedMonthlyUSD?.usd
        chargeDayOfMonth = domain.chargeDayOfMonth
        reportedAmountUSD = domain.reportedAmountUSD?.usd
        reportedAmountYear = domain.reportedAmountMonth?.year
        reportedAmountMonth = domain.reportedAmountMonth?.month
    }

    /// 解不出来的行当**不存在**处理。这张表是缓存，缺一行重折就有；
    /// 读成默认值会在界面上留下一个查无源头的余额。
    public func toDomain() -> AccountLatest? {
        guard
            let uuid = UUID(uuidString: accountIDRaw),
            let kind = ProviderKind(rawValue: kindRaw)
        else {
            return nil
        }
        return AccountLatest(
            accountID: AccountID(rawValue: uuid),
            providerID: ProviderID(rawValue: providerIDRaw),
            kind: kind,
            fetchedAt: fetchedAt,
            source: SnapshotSource(rawValue: sourceRaw) ?? .api,
            balanceUSD: balanceUSD.map(Money.init(usd:)),
            balanceOriginalCurrency: balanceCurrency,
            balanceUSDPerUnit: balanceRate,
            freeQuotaUsedRatio: freeQuotaUsedRatio,
            committedMonthlyUSD: committedMonthlyUSD.map(Money.init(usd:)),
            chargeDayOfMonth: chargeDayOfMonth,
            reportedAmountUSD: reportedAmountUSD.map(Money.init(usd:)),
            reportedAmountMonth: storedReportedMonth
        )
    }

    /// 年月要么齐要么全 nil——`init` 从同一个 `MonthKey?` 一次写入。
    private var storedReportedMonth: MonthKey? {
        guard let reportedAmountYear, let reportedAmountMonth else { return nil }
        return MonthKey(year: reportedAmountYear, month: reportedAmountMonth)
    }
}
