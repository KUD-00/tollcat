import Foundation
import SwiftData
import MeterCore

/// 物化账本的一行落库。**（账号, 月）唯一。**
///
/// 这张表是**缓存**，不是真相——`SnapshotRecord` 才是。任何时候都能整份删掉、
/// 从快照重建，而且重建结果必须和全量重算逐项相同（`LedgerSelfCheck` 守这条）。
/// 正因为它可以被丢掉，这张表不进迁移包、也不需要为它写任何数据迁移：
/// 加这张表对旧库是纯增量，第一次启动时是空的，折一遍就有了。
///
/// 唯一性靠 `MonthlyLedgerStore` 的"先查再写"保证，不用 `#Unique`：
/// 约束一旦进了 schema，将来想改主键就变成一次真的迁移，而这张表本来就该
/// 随手可弃。
@Model
public final class MonthlyRollupRecord {
    /// 增量重折按 `accountIDRaw` 取这一家的全部行。
    /// 索引不是唯一约束——见上面那段为什么这张表不上 `#Unique`。
    #Index<MonthlyRollupRecord>([\.accountIDRaw])

    public var accountIDRaw: String
    public var providerIDRaw: String
    /// 哪一年哪一月。**存分量，不存「1 号零点」那一刻**：那一刻随时区变，
    /// 东京的 8 月 1 日零点在纽约日历上是 7 月 31 日，投影按精确时刻匹配就一行都对不上。
    /// 见 `MonthKey`。
    public var monthYear: Int = 0
    public var monthOfYear: Int = 0

    /// `Money` 按 `Decimal` 落库，和 `SnapshotRecord` 同一条规矩——
    /// 用 `Double` 会让分位被二进制浮点改掉，而这张表存的就是钱。
    public var usageUSD: Decimal
    public var prepaidUSD: Decimal
    public var subscriptionUSD: Decimal

    public var confidenceRaw: String
    public var isEstimated: Bool
    public var didFailFetch: Bool
    /// 这个月这个账号**有没有读数**。「没数据」和「$0」是两件事，
    /// 而账本会给每个账号铺满 12 个月，所以不能靠"有没有行"分辨。
    public var hasReading: Bool

    /// 「上月同期」，按 fact 类型分开。`nil` 表示**这一家还不能比**，
    /// 和「上个月是 0」是两件事——混起来涨跌幅会变成 +∞。
    public var comparisonUsageUSD: Decimal?
    public var comparisonPrepaidUSD: Decimal?
    public var comparisonSubscriptionUSD: Decimal?
    /// 折这一行时当作「此刻」的时间点。同期比的是上个月到"今天"为止，
    /// 所以当月那一行跨一天就过期——「今天」那一项在 `LedgerFingerprint` 里，
    /// 跨天整份都会重折。这一列留着是为了看得见每一行是按哪一刻折的。
    public var foldedAsOf: Date = Date.distantPast

    /// 压平之后的日粒度，至多 31 条。和 `SnapshotRecord.dailySpendData` 同一个编码。
    public var dailySpendData: Data?
    /// 该月每天最后一次观测到的余额，编码同上。「还能撑几天」查这张表。
    public var dailyBalanceData: Data?
    /// 该月的明细行（钱去了哪个类别）。和 `SnapshotRecord.spendLinesData` 同一个编码。
    public var spendLinesData: Data?
    /// 折这一行时产出过哪几类事实，逗号分隔的 rawValue。
    /// 「有没有这一条」和「金额是多少」是两件事——见 `MonthlyRollup.producedFactKinds`。
    public var producedFactKindsRaw: String = ""
    /// 免费额度已用比例——瞬时值，不是可加的历史。
    public var freeQuotaUsedRatio: Double?
    public var latestKindRaw: String?
    /// 折这一行时账号手上最新那条快照的 `fetchedAt`。
    ///
    /// **不再拿它当"账本还作不作数"的判据**：补一条更老的读数时它纹丝不动，
    /// 而账本已经该重折了。那件事现在归 `LedgerFingerprint`。这一列是给人看的——
    /// 一行的数字停在哪儿，从这里能一眼看出来。
    public var foldedThrough: Date

    /// `calendar` 是折叠用的那本：月份分量和日表的键都按它翻。
    ///
    /// **编码失败就抛**，不落一行半对的。理由同 `toDomain`：半边对的状态
    /// （总数在、日表空）比整行缺失难发现得多。
    public init(domain: MonthlyRollup, calendar: Calendar) throws {
        self.accountIDRaw = domain.accountID.rawValue.uuidString
        self.providerIDRaw = domain.providerID.rawValue
        let month = MonthKey(domain.monthStart, calendar: calendar)
        self.monthYear = month.year
        self.monthOfYear = month.month
        self.usageUSD = domain.usageUSD.usd
        self.prepaidUSD = domain.prepaidUSD.usd
        self.subscriptionUSD = domain.subscriptionUSD.usd
        self.confidenceRaw = domain.confidence.rawValue
        self.isEstimated = domain.isEstimated
        self.didFailFetch = domain.didFailFetch
        self.hasReading = domain.hasReading
        self.dailySpendData = try DailySpendCodec.encode(domain.dailyUSD, calendar: calendar)
        self.dailyBalanceData = try DailySpendCodec.encode(domain.dailyBalanceUSD, calendar: calendar)
        self.spendLinesData = try SpendLineCodec.encode(domain.lines)
        self.producedFactKindsRaw = Self.encodeKinds(domain.producedFactKinds)
        self.freeQuotaUsedRatio = domain.freeQuotaUsedRatio
        self.comparisonUsageUSD = domain.comparisonUsageUSD?.usd
        self.comparisonPrepaidUSD = domain.comparisonPrepaidUSD?.usd
        self.comparisonSubscriptionUSD = domain.comparisonSubscriptionUSD?.usd
        self.foldedAsOf = domain.foldedAsOf
        self.latestKindRaw = domain.latestKind?.rawValue
        self.foldedThrough = domain.foldedThrough
    }

    public var monthKey: MonthKey { MonthKey(year: monthYear, month: monthOfYear) }

    public func apply(_ domain: MonthlyRollup, calendar: Calendar) throws {
        providerIDRaw = domain.providerID.rawValue
        let month = MonthKey(domain.monthStart, calendar: calendar)
        monthYear = month.year
        monthOfYear = month.month
        usageUSD = domain.usageUSD.usd
        prepaidUSD = domain.prepaidUSD.usd
        subscriptionUSD = domain.subscriptionUSD.usd
        confidenceRaw = domain.confidence.rawValue
        isEstimated = domain.isEstimated
        didFailFetch = domain.didFailFetch
        hasReading = domain.hasReading
        dailySpendData = try DailySpendCodec.encode(domain.dailyUSD, calendar: calendar)
        dailyBalanceData = try DailySpendCodec.encode(domain.dailyBalanceUSD, calendar: calendar)
        spendLinesData = try SpendLineCodec.encode(domain.lines)
        producedFactKindsRaw = Self.encodeKinds(domain.producedFactKinds)
        freeQuotaUsedRatio = domain.freeQuotaUsedRatio
        comparisonUsageUSD = domain.comparisonUsageUSD?.usd
        comparisonPrepaidUSD = domain.comparisonPrepaidUSD?.usd
        comparisonSubscriptionUSD = domain.comparisonSubscriptionUSD?.usd
        foldedAsOf = domain.foldedAsOf
        latestKindRaw = domain.latestKind?.rawValue
        foldedThrough = domain.foldedThrough
    }

    /// 排序后再拼：同一行每次落盘字节相同。
    private static func encodeKinds(_ kinds: Set<FactKind>) -> String {
        kinds.map(\.rawValue).sorted().joined(separator: ",")
    }

    private static func decodeKinds(_ raw: String) -> Set<FactKind> {
        Set(raw.split(separator: ",").compactMap { FactKind(rawValue: String($0)) })
    }

    /// 解不出来的行当**不存在**处理，不当成 $0。
    ///
    /// 这张表是缓存，把坏行读成 $0 会在总数里留下一个静悄悄少掉的账号，
    /// 那比缺一行糟得多。
    ///
    /// 但「丢掉」只是这一步的事：**读到坏行会作废戳**（见 `MonthlyLedgerStore.all`），
    /// 于是下一次 `isInSync` 必定判失效、整份重折。这里以前写着「重折一次就有了」，
    /// 而那时没有任何人会去重折——指纹比的是输入，一行解不出来时输入没变，
    /// 那个账号那个月就从合计里**永久**消失了。
    ///
    /// 这条对**每一个** blob 都成立，不只是 uuid 和 confidence。日表解不出来时
    /// 读成空字典的话，行照样进合计——总数看起来完全正常，而热力图、按日同期
    /// 整块空掉。半边对的状态比整行缺失难发现得多。
    ///
    /// 「没有这一段」和「这一段坏了」也必须分开：`decode(nil)` 回 nil 是前者，
    /// 抛错才是后者。`try?` 会把两者压成同一个 nil，所以这里用 `do / catch`。
    public func toDomain(calendar: Calendar) -> MonthlyRollup? {
        guard
            let uuid = UUID(uuidString: accountIDRaw),
            let confidence = Confidence(rawValue: confidenceRaw),
            let monthStart = monthKey.monthStart(in: calendar)
        else {
            return nil
        }
        let daily: [Date: Money]?
        let dailyBalance: [Date: Money]?
        let lines: [SpendLine]?
        do {
            daily = try DailySpendCodec.decode(dailySpendData, calendar: calendar)
            dailyBalance = try DailySpendCodec.decode(dailyBalanceData, calendar: calendar)
            lines = try SpendLineCodec.decode(spendLinesData)
        } catch {
            return nil
        }
        return MonthlyRollup(
            accountID: AccountID(rawValue: uuid),
            providerID: ProviderID(rawValue: providerIDRaw),
            monthStart: monthStart,
            usageUSD: Money(usd: usageUSD),
            prepaidUSD: Money(usd: prepaidUSD),
            subscriptionUSD: Money(usd: subscriptionUSD),
            confidence: confidence,
            isEstimated: isEstimated,
            didFailFetch: didFailFetch,
            hasReading: hasReading,
            dailyUSD: daily ?? [:],
            dailyBalanceUSD: dailyBalance ?? [:],
            lines: lines,
            producedFactKinds: Self.decodeKinds(producedFactKindsRaw),
            freeQuotaUsedRatio: freeQuotaUsedRatio,
            comparisonUsageUSD: comparisonUsageUSD.map(Money.init(usd:)),
            comparisonPrepaidUSD: comparisonPrepaidUSD.map(Money.init(usd:)),
            comparisonSubscriptionUSD: comparisonSubscriptionUSD.map(Money.init(usd:)),
            foldedAsOf: foldedAsOf,
            latestKind: latestKindRaw.flatMap(ProviderKind.init(rawValue:)),
            foldedThrough: foldedThrough
        )
    }
}
