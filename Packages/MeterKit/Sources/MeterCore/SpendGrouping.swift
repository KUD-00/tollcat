import Foundation

/// 「花在哪了」的分组：`[SpendLine]` → 排好序、折叠过、算好占比的几组。
///
/// **纯值，一个字都不写。** 金额怎么写、「额度抵扣 …」那句怎么拼，是
/// `MeterFormat` 和各平台的事；但**分到哪一组、谁排前面、超出几组折成「其他」、
/// 占比怎么算**只有这一份。
///
/// 它曾经有两份：`MeterFeatures/SpendBreakdownBuilder` 一份，Android 的
/// `SpendBreakdownBuilder.kt` 一份手译的。桥上明明已经在送 `lines` 了，
/// 却在 Kotlin 里把这套加法又做了一遍。
public enum SpendGrouping: Sendable {
    /// 一屏最多列几组。再多就没人看了，尾巴并成「其他」。
    public static let maxGroups = 6

    public static func make(lines: [SpendLine]?, mode: SpendGroupingMode) -> SpendGroups {
        guard let lines, !lines.isEmpty else { return .empty }

        let supportsScope = lines.contains { $0.scope != nil }
        // 选了「按归属」但这份数据没有归属维度：退回按类别，而不是给一屏空的。
        let effective: SpendGroupingMode = (mode == .scope && !supportsScope) ? .category : mode

        let total = lines.reduce(Money.zero) { $0 + $1.amountUSD }
        let hasList = lines.contains { $0.listUSD != nil }
        let listTotal = lines.compactMap(\.listUSD).reduce(Money.zero, +)

        let buckets = collapsed(bucketed(lines, by: effective)).map { bucket in
            grouped(bucket, total: total, listTotal: listTotal, mode: effective)
        }

        return SpendGroups(
            buckets: buckets,
            mode: effective,
            supportsScope: supportsScope,
            total: total,
            listTotal: hasList ? listTotal : nil,
            itemCount: lines.count
        )
    }

    // MARK: - 分桶

    private struct Bucket {
        var key: String
        var title: String
        var isOther: Bool
        var amount: Money
        var list: Money?
        var quantity: Decimal?
        var unit: String?
        var lines: [SpendLine]

        /// 组里只有一条时把那条的额度说明提上来。多条时不提——
        /// 「(First 500 GB included)」是那一条服务的额度，不是整个产品线的。
        var allowanceNote: String? {
            lines.count == 1 ? lines[0].allowanceNote : nil
        }
    }

    private static func bucketed(_ lines: [SpendLine], by mode: SpendGroupingMode) -> [Bucket] {
        var order: [String] = []
        var buckets: [String: Bucket] = [:]
        for line in lines {
            let title: String
            switch mode {
            case .category:
                title = line.category
            case .scope:
                // 走到这里说明整份数据有 scope 维度，但个别行可能仍然没有。
                title = line.scope ?? line.category
            }
            if var existing = buckets[title] {
                existing.amount += line.amountUSD
                existing.list = sum(existing.list, line.listUSD)
                if existing.unit == line.unit {
                    existing.quantity = sum(existing.quantity, line.quantity)
                } else {
                    existing.quantity = nil
                    existing.unit = nil
                }
                existing.lines.append(line)
                buckets[title] = existing
            } else {
                order.append(title)
                buckets[title] = Bucket(
                    key: title,
                    title: title,
                    isOther: false,
                    amount: line.amountUSD,
                    list: line.listUSD,
                    quantity: line.quantity,
                    unit: line.unit,
                    lines: [line]
                )
            }
        }
        return order.compactMap { buckets[$0] }.sorted { lhs, rhs in
            if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
            // 全被额度抵掉的家里金额全是 0，再按名字排就变成字母序——
            // 构成条会从小到大画出来，看着像坏了。并列时按原价分大小。
            let lhsList = lhs.list?.usd ?? 0
            let rhsList = rhs.list?.usd ?? 0
            if lhsList != rhsList { return lhsList > rhsList }
            return lhs.title < rhs.title
        }
    }

    /// 超出 `maxGroups` 的尾巴并成「其他」。并进去的行仍然完整保留在 `items` 里，
    /// 展开还能看见是谁——折叠是视觉上的，不是把数据丢了。
    private static func collapsed(_ buckets: [Bucket]) -> [Bucket] {
        guard buckets.count > maxGroups else { return buckets }
        let head = Array(buckets.prefix(maxGroups - 1))
        let tail = Array(buckets.dropFirst(maxGroups - 1))
        let lists = tail.compactMap(\.list)
        let other = Bucket(
            key: otherKey,
            title: "",
            isOther: true,
            amount: tail.reduce(Money.zero) { $0 + $1.amount },
            list: lists.isEmpty ? nil : lists.reduce(Money.zero, +),
            quantity: nil,
            unit: nil,
            lines: tail.flatMap(\.lines)
        )
        return head + [other]
    }

    /// 「其他」那一组的 id。调用方按它决定标题写「其他」。
    public static let otherKey = "__other__"

    // MARK: - 成型

    private static func grouped(
        _ bucket: Bucket,
        total: Money,
        listTotal: Money,
        mode: SpendGroupingMode
    ) -> SpendGroupedBucket {
        // 整组只有一个归属时，行里不再重复写它——组内每行都挂着同一个仓库名／
        // 项目 id，除了把标题撑到换行之外不提供任何信息。
        let spansScopes = Set(bucket.lines.map { $0.scope ?? "" }).count > 1
        let items = bucket.lines
            .sorted { lhs, rhs in
                if lhs.amountUSD != rhs.amountUSD { return lhs.amountUSD > rhs.amountUSD }
                let lhsList = lhs.listUSD?.usd ?? 0
                let rhsList = rhs.listUSD?.usd ?? 0
                if lhsList != rhsList { return lhsList > rhsList }
                return lhs.label < rhs.label
            }
            .enumerated()
            .map { index, line in
                SpendGroupedItem(
                    id: "\(line.category)|\(line.label)|\(line.scope ?? "")|\(index)",
                    title: itemTitle(line, mode: mode, spansScopes: spansScopes),
                    line: line
                )
            }
        return SpendGroupedBucket(
            id: bucket.key,
            title: bucket.title,
            isOther: bucket.isOther,
            amount: bucket.amount,
            list: bucket.list,
            quantity: bucket.quantity,
            unit: bucket.unit,
            fraction: fraction(
                amount: bucket.amount,
                total: total,
                list: bucket.list,
                listTotal: listTotal
            ),
            share: share(amount: bucket.amount, total: total),
            discount: bucket.list.flatMap { list in
                list.usd > bucket.amount.usd ? list - bucket.amount : nil
            },
            allowanceNote: bucket.allowanceNote,
            isZeroBilled: bucket.amount.roundedToCents() == .zero,
            items: items
        )
    }

    private static func itemTitle(
        _ line: SpendLine,
        mode: SpendGroupingMode,
        spansScopes: Bool
    ) -> String {
        // 按类别分组时，行里值得多说一句的是「哪个仓库 / 哪个项目」；按归属分组时反过来。
        switch mode {
        case .category:
            guard spansScopes, let scope = line.scope else { return line.label }
            // 没有第二层名字的家（Vercel 的 category 就是 ServiceName），
            // 行里只写归属，否则是「Fluid Compute · Fluid Compute · demo」那种。
            return line.label == line.category ? scope : "\(line.label) · \(scope)"
        case .scope:
            return line.label
        }
    }

    /// 百分比只在真花了钱时给。合计为 0 时 `fraction` 是原价占比，
    /// 写成「71%」会被读成"花了七成"，那是假话。
    private static func share(amount: Money, total: Money) -> SpendShare {
        guard total.usd > 0, amount.usd > 0 else { return .none }
        let percent = ratio(amount.usd, total.usd) * 100
        guard percent.isFinite else { return .none }
        // 不足 1% 的写「<1%」而不是「0%」——0% 看起来像没用过。
        if percent < 1 { return .belowOnePercent }
        return .percent(Int(percent.rounded()))
    }

    /// 钱的占比。全被免费额度抵掉时合计是 0，退回**原价**占比——
    /// 否则「谁在烧额度」这一屏所有条都是空的。
    ///
    /// 退回的是原价而不是用量。用量跨单位不可比：GitHub 的 actions 组里
    /// 既有 Minutes 又有 GigabyteHours，合并后 `quantity` 直接是 nil，
    /// 拿它算占比会得出「packages 占 100%」这种假话。原价是钱，永远可比。
    private static func fraction(
        amount: Money,
        total: Money,
        list: Money?,
        listTotal: Money
    ) -> Double {
        if total.usd > 0 { return clamp(ratio(amount.usd, total.usd)) }
        if let list, listTotal.usd > 0 { return clamp(ratio(list.usd, listTotal.usd)) }
        return 0
    }

    private static func ratio(_ value: Decimal, _ total: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue / NSDecimalNumber(decimal: total).doubleValue
    }

    private static func clamp(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
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

/// 明细分组的两个维度。`scope` 那一维不是每家都有，能不能选由内容决定。
public enum SpendGroupingMode: String, Hashable, Sendable, CaseIterable {
    /// 按类别（Cloudflare 的产品线、GitHub 的 product）。
    case category
    /// 按归属（仓库 / project / 数据库）。
    case scope
}

/// 占比。**三态，不是可空的数字**：「不给」和「不足 1%」是两件事。
public enum SpendShare: Equatable, Sendable {
    /// 合计为 0（全被额度抵掉），或这一组自己是 0。不写百分比。
    case none
    /// 「<1%」。写成 0% 看起来像没用过。
    case belowOnePercent
    case percent(Int)
}

public struct SpendGroupedItem: Equatable, Sendable {
    public var id: String
    public var title: String
    public var line: SpendLine

    public init(id: String, title: String, line: SpendLine) {
        self.id = id
        self.title = title
        self.line = line
    }
}

public struct SpendGroupedBucket: Equatable, Sendable {
    public var id: String
    /// `isOther` 时是空串——「其他」这两个字要本地化，不在 Core 里写。
    public var title: String
    public var isOther: Bool
    public var amount: Money
    public var list: Money?
    public var quantity: Decimal?
    public var unit: String?
    /// 占明细合计的比例，`0...1`。
    public var fraction: Double
    public var share: SpendShare
    /// 被额度或折扣挡掉的部分。没有原价信息时是 nil。
    public var discount: Money?
    public var allowanceNote: String?
    /// 实收到分都是 0。详情页预览不拿这种组去凑槽位。
    public var isZeroBilled: Bool
    public var items: [SpendGroupedItem]

    public init(
        id: String,
        title: String,
        isOther: Bool,
        amount: Money,
        list: Money?,
        quantity: Decimal?,
        unit: String?,
        fraction: Double,
        share: SpendShare,
        discount: Money?,
        allowanceNote: String?,
        isZeroBilled: Bool,
        items: [SpendGroupedItem]
    ) {
        self.id = id
        self.title = title
        self.isOther = isOther
        self.amount = amount
        self.list = list
        self.quantity = quantity
        self.unit = unit
        self.fraction = fraction
        self.share = share
        self.discount = discount
        self.allowanceNote = allowanceNote
        self.isZeroBilled = isZeroBilled
        self.items = items
    }
}

public struct SpendGroups: Equatable, Sendable {
    public var buckets: [SpendGroupedBucket]
    public var mode: SpendGroupingMode
    /// 能不能切到「按归属」。整份明细一个 `scope` 都没有时是 false。
    public var supportsScope: Bool
    /// 明细自身的合计。**不等于快照的 `currentSpendUSD`**——见 `Snapshot.lines` 的说明。
    public var total: Money
    /// 原价合计。一条都没给原价时是 nil。
    public var listTotal: Money?
    /// 原始明细条数，用于「全部 N 项」那个入口。不是分组数——折叠成「其他」的也算。
    public var itemCount: Int

    public init(
        buckets: [SpendGroupedBucket],
        mode: SpendGroupingMode,
        supportsScope: Bool,
        total: Money,
        listTotal: Money?,
        itemCount: Int
    ) {
        self.buckets = buckets
        self.mode = mode
        self.supportsScope = supportsScope
        self.total = total
        self.listTotal = listTotal
        self.itemCount = itemCount
    }

    public var isEmpty: Bool { buckets.isEmpty }

    /// 原价比实收高出来的那一截。没有原价信息、或没被抵扣时是 nil。
    public var savedTotal: Money? {
        guard let listTotal, listTotal.usd > total.usd else { return nil }
        return listTotal - total
    }

    public static let empty = SpendGroups(
        buckets: [],
        mode: .category,
        supportsScope: false,
        total: .zero,
        listTotal: nil,
        itemCount: 0
    )
}
