import Foundation

/// 一条账单明细：这家的钱花在了哪个东西上。
///
/// **为什么要归一化，而不是各家原样透传。** 厂商的词汇表各不相同——Cloudflare 叫
/// `ServiceFamilyName` / `ServiceName`，GitHub 叫 `product` / `sku` / `repositoryName`，
/// Neon 叫 `metric_name` / `project_id`。如果让这些原词一路走到界面，
/// 每加一家就要加一份 UI。这里把它们压成同一组维度：**分到哪一类、叫什么、
/// 记在谁头上**。适配器负责翻译，界面只认这三个维度，一份代码画所有家。
///
/// 界面上的"定制"因此是**数据差异**而不是代码差异：`scope` 有值的家多一个
/// 分组切换，`listUSD` 有值的家多一行"抵扣了多少"，别的什么都不用改。
///
/// **粒度是"本账期合计"，不是按天。** 快照每次刷新都落库、永不删除，
/// 按天 × 按服务会把一条快照撑到几百行。日粒度的需求先由 `Snapshot.dailyUSD`
/// 顶着；真要画按服务的堆叠面积图，再单独给这里加 `day`。
public struct SpendLine: Hashable, Sendable {
    /// 分到哪一类。用于分组和配色：Cloudflare 的产品线、GitHub 的 product。
    public var category: String
    /// 这一条自己的名字。Cloudflare 的 `ServiceName`、GitHub 的 `sku`。
    public var label: String
    /// 记在谁头上：仓库名 / project id / 数据库 id。厂商不按这个维度切就是 nil。
    public var scope: String?
    /// 实收。被免费额度吃掉的那些是 `.zero`——**不要因此把行丢掉**，
    /// "免费额度替你挡了多少"本身就是用户想看的。
    public var amountUSD: Money
    /// 原价。厂商同时给了原价和实收才填（GitHub `grossAmount`、Cloudflare `ListCost`）。
    public var listUSD: Money?
    public var quantity: Decimal?
    /// 单位原文，不翻译。"GigabyteHours" / "vCPU-seconds" 直接给用户看，
    /// 比译成"千兆字节小时"更容易和厂商后台对上。
    public var unit: String?
    /// 厂商自己写在服务名里的免费额度说明，**原样透传，不解析成数字**。
    ///
    /// Cloudflare 的 `ServiceName` 长这样：
    /// `Container Egress, Oceania, Taiwan, and Korea, per GB (First 500 GB included)`。
    /// 括号里那句才是"为什么这条是 $0"的答案，但塞在标题里会把一行撑爆。
    /// 拆出来放次要位置，标题留干净的服务名。
    /// 解析成 `includedQuantity: Decimal` 是下一步的事——现在没有第二家能填，
    /// 提前造一个只有一家填得上的数字字段是在猜。
    public var allowanceNote: String?

    public init(
        category: String,
        label: String,
        scope: String? = nil,
        amountUSD: Money,
        listUSD: Money? = nil,
        quantity: Decimal? = nil,
        unit: String? = nil,
        allowanceNote: String? = nil
    ) {
        self.category = category
        self.label = label
        self.scope = scope
        self.amountUSD = amountUSD
        self.listUSD = listUSD
        self.quantity = quantity
        self.unit = unit
        self.allowanceNote = allowanceNote
    }

    /// 被免费额度或折扣挡掉的部分。原价缺失、或原价反而更低时是 nil——
    /// 不编造一个负的"省了多少"。
    public var discountUSD: Money? {
        guard let listUSD, listUSD.usd > amountUSD.usd else { return nil }
        return listUSD - amountUSD
    }

    /// 合并同一格的两条。金额相加，用量只在单位一致时相加——
    /// 单位不同的数量加起来没有意义，宁可不给数也不给错的数。
    public func merging(_ other: SpendLine) -> SpendLine {
        var result = self
        result.amountUSD += other.amountUSD
        result.listUSD = Self.sum(listUSD, other.listUSD)
        if unit == other.unit {
            result.quantity = Self.sum(quantity, other.quantity)
        } else {
            result.quantity = nil
            result.unit = nil
        }
        result.allowanceNote = allowanceNote ?? other.allowanceNote
        return result
    }

    private static func sum(_ lhs: Money?, _ rhs: Money?) -> Money? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs + rhs
    }

    private static func sum(_ lhs: Decimal?, _ rhs: Decimal?) -> Decimal? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs + rhs
    }
}
