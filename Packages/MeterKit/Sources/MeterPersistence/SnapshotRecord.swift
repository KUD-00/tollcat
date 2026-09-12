import Foundation
import SwiftData
import MeterCore

/// 每次刷新写一条。趋势图只认这些行，删了就无法重算历史。
///
/// 「永不删除」是**读取契约**，不是存储契约：能回看的窗口以内一条都不能少，
/// 窗口以外（13 个月前）每（账号, 月）只需要留最后一条。规则写在
/// SPEC 第 12.5 节「快照压缩策略」，实现还没做——**别在这里加一句永不删除
/// 就当没有增长问题**。
@Model
public final class SnapshotRecord {
    /// 这张表只增不删，装久了就是几千上万行。两条查询几乎是它的全部用途：
    /// 首屏「最近 500 条」（按 `fetchedAt` 倒着取）和折叠时按账号取一段历史。
    /// 没有索引这两条都是全表扫 + 排序，代价和刷新次数成正比——而刷新次数
    /// 是这个 App 里唯一会一直涨的东西。
    #Index<SnapshotRecord>([\.fetchedAt], [\.accountIDRaw], [\.accountIDRaw, \.fetchedAt])

    public var accountIDRaw: String
    public var providerIDRaw: String
    public var kindRaw: String
    public var sourceRaw: String = SnapshotSource.api.rawValue
    /// 取到这条数的那一刻。**这一列是真正的瞬间**，不改存法（排序索引也在它上面）。
    public var fetchedAt: Date
    /// 账期端点，**加分量列之前**写下的形状：某个时区的那一刻。
    ///
    /// 只为读旧行留着，新行两边都写。读的时候优先认下面那两列——
    /// 存瞬间的账期端点在换时区之后会整体挪一天，而 `proratePeriodSpend`
    /// 会把整笔钱摊到错的月份上（见 `Snapshot.periodStart` 那段）。
    public var periodStart: Date
    public var periodEnd: Date
    /// 账期端点的日历分量（`DayKey.storageString`，`yyyy-MM-dd`）。
    ///
    /// 空串 = 加这两列之前写下的旧行，回落到上面两列。带默认值走轻量迁移。
    /// 「日历日只存分量」这条规矩现在覆盖四处：厂商日桶、账本行的月份、
    /// 订阅的锚点、以及这里的账期端点（`ProviderConfigRecord.archivedDay` 同族）。
    public var periodStartDay: String = ""
    public var periodEndDay: String = ""
    /// `Money` 按 `Decimal` 落库，不用 `Double`，避免分位被二进制浮点改掉。
    public var currentSpendUSD: Decimal?
    public var balanceUSD: Decimal?
    public var committedMonthlyUSD: Decimal?
    public var chargeDayOfMonth: Int?
    public var freeQuotaUsedRatio: Double?
    public var dailySpendData: Data?
    /// 换算说明。可选是语义：大多数快照没换过币，四个都是 nil。
    public var convertedCurrency: String?
    public var convertedAmount: Decimal?
    public var convertedRate: Decimal?
    /// 换算之后是多少美元。**必须自己存一列。**
    ///
    /// 以前它是从 `currentSpendUSD ?? balanceUSD ?? committedMonthlyUSD` 里猜的，
    /// 而 `planAndUsage` 这种两个槽都有钱的 kind 会猜到错的那一个——
    /// 详情页大数字底下那行「（1 CNY = $0.14）」于是对着一个不相干的金额算。
    public var convertedUSD: Decimal? = nil
    /// 预充值多币种钱包。和 `dailySpendData` 一样用 JSON，三个换算列装不下数组。
    public var walletsData: Data? = nil
    /// 本账期的明细。同样是 JSON——列存不下，而且各家维度数不一样。
    /// 存的是**已经按 (类别, 名称, 归属) 合过的**行，不是原始逐日逐 sku，
    /// 否则每次刷新都往这张永不删除的表里塞几百条。
    public var spendLinesData: Data? = nil

    /// `calendar` 是落盘日历：日表的键存成日历上的那一天（`DayKey`），不存时刻。
    ///
    /// **编码失败就抛。**以前这里是 `try?`：日表 / 钱包 / 明细编不出来就落 nil，
    /// 一条读数照样写进这张永不删除的表，只是少了三段——总数看起来完全正常，
    /// 热力图和按日同期整块空掉。编不出来 = 这次刷新写库失败，走
    /// `RefreshPipeline` 已有的「落盘失败不算成功」那一支。
    public init(domain: Snapshot, calendar: Calendar) throws {
        self.accountIDRaw = domain.accountID?.rawValue.uuidString ?? ""
        self.providerIDRaw = domain.providerID.rawValue
        self.kindRaw = domain.kind.rawValue
        self.sourceRaw = domain.source.rawValue
        self.fetchedAt = domain.fetchedAt
        self.periodStart = domain.periodStart
        self.periodEnd = domain.periodEnd
        self.periodStartDay = DayKey(domain.periodStart, calendar: calendar).storageString
        self.periodEndDay = DayKey(domain.periodEnd, calendar: calendar).storageString
        self.currentSpendUSD = domain.currentSpendUSD?.usd
        self.balanceUSD = domain.balanceUSD?.usd
        self.committedMonthlyUSD = domain.committedMonthlyUSD?.usd
        self.chargeDayOfMonth = domain.chargeDayOfMonth
        self.freeQuotaUsedRatio = domain.freeQuotaUsedRatio
        self.dailySpendData = try DailySpendCodec.encode(domain.dailyUSD, calendar: calendar)
        self.convertedCurrency = domain.converted?.currency
        self.convertedAmount = domain.converted?.amount
        self.convertedRate = domain.converted?.usdPerUnit
        self.convertedUSD = domain.converted?.usd
        self.walletsData = try WalletBalanceCodec.encode(domain.wallets)
        self.spendLinesData = try SpendLineCodec.encode(domain.lines)
    }

    /// 日表按 `calendar` 还原成那一天的零点。换了时区再读一次就是新时区的那一天，
    /// 不需要迁移——存的是分量，不是时刻。
    public func toDomain(calendar: Calendar) throws -> Snapshot {
        guard let kind = ProviderKind(rawValue: kindRaw) else {
            throw PersistenceError.invalidStoredKind(kindRaw)
        }
        guard let uuid = UUID(uuidString: accountIDRaw) else {
            throw PersistenceError.invalidStoredAccount(accountIDRaw)
        }
        return Snapshot(
            providerID: ProviderID(providerIDRaw),
            accountID: AccountID(rawValue: uuid),
            kind: kind,
            source: SnapshotSource(rawValue: sourceRaw) ?? .api,
            fetchedAt: fetchedAt,
            periodStart: Self.day(periodStartDay, in: calendar) ?? periodStart,
            periodEnd: Self.day(periodEndDay, in: calendar) ?? periodEnd,
            currentSpendUSD: currentSpendUSD.map(Money.init(usd:)),
            balanceUSD: balanceUSD.map(Money.init(usd:)),
            committedMonthlyUSD: committedMonthlyUSD.map(Money.init(usd:)),
            chargeDayOfMonth: chargeDayOfMonth,
            freeQuotaUsedRatio: freeQuotaUsedRatio,
            dailyUSD: try DailySpendCodec.decode(dailySpendData, calendar: calendar),
            converted: storedConverted,
            wallets: try WalletBalanceCodec.decode(walletsData),
            lines: try SpendLineCodec.decode(spendLinesData)
        )
    }

    /// 分量列还原成这本日历上那一天的零点。空串（旧行）或分量不合法回 nil，
    /// 调用方回落到旧的瞬间列——不猜。
    static func day(_ raw: String, in calendar: Calendar) -> Date? {
        DayKey(storageString: raw)?.date(in: calendar)
    }

    /// init 从同一个 `domain.converted?` 一次性写入，四个字段要么齐要么全 nil。
    private var storedConverted: ConvertedAmount? {
        guard let convertedCurrency, let convertedAmount, let convertedRate else { return nil }
        return ConvertedAmount(
            currency: convertedCurrency,
            amount: convertedAmount,
            usdPerUnit: convertedRate,
            // 后面那串只服务**加上 `convertedUSD` 这一列之前**写下的行。
            // 它是猜的（见那一列的注释），但比把这条读成「没换过币」好：
            // 后者会让这家从「哪几家是估的」名单里消失。
            usd: convertedUSD ?? currentSpendUSD ?? balanceUSD ?? committedMonthlyUSD ?? 0
        )
    }
}
