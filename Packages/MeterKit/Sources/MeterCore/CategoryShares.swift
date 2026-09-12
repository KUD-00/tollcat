import Foundation

/// 「按类别构成」的加法：几十家收成几段，算出每段占多少。
///
/// **百分比走 `IntegerPercents`（最大余数），保证加起来正好 100。** 各段自己
/// 四舍五入会凑出 99 或 101——图例底下那一列数字加不到 100，看着就是坏的。
/// 这一条曾经只有 Apple 侧守着：Android 桥自己按比例 `round()` 了一遍。
public enum CategoryShares: Sendable {
    public static func make(from members: [CategoryShareMember]) -> [CategoryShare] {
        guard !members.isEmpty else { return [] }

        struct Bucket {
            var amount: Money = .zero
            var leadColorKey = "unknown"
            var leadAmount: Money = .zero
            var names: [String] = []
        }
        var buckets: [ProviderCategory: Bucket] = [:]
        for member in members {
            let category = member.providerID.flatMap { ProviderIdentity.known($0)?.category } ?? .other
            var bucket = buckets[category] ?? Bucket()
            bucket.amount += member.amount
            bucket.names.append(member.displayName)
            // 段的颜色跟段里花最多那家，不另造一套调色板。
            if member.amount.usd > bucket.leadAmount.usd {
                bucket.leadAmount = member.amount
                bucket.leadColorKey = member.colorKey
            }
            buckets[category] = bucket
        }

        let total = buckets.values.reduce(Money.zero) { $0 + $1.amount }
        guard total.usd > 0 else { return [] }
        let totalValue = NSDecimalNumber(decimal: total.usd).doubleValue
        let sorted = buckets.sorted { lhs, rhs in
            if lhs.value.amount.usd != rhs.value.amount.usd {
                return lhs.value.amount.usd > rhs.value.amount.usd
            }
            // 并列时按类别 rawValue 定序，免得 Dictionary 的顺序每次不一样。
            return lhs.key.rawValue < rhs.key.rawValue
        }
        let percents = IntegerPercents.from(weights: sorted.map { $0.value.amount.usd })
        return zip(sorted, percents).map { entry, percent in
            CategoryShare(
                category: entry.key,
                amount: entry.value.amount,
                fraction: NSDecimalNumber(decimal: entry.value.amount.usd).doubleValue / totalValue,
                percent: percent,
                colorKey: entry.value.leadColorKey,
                memberNames: entry.value.names
            )
        }
    }
}

/// 进这台加法机的一份钱：谁家、多少、什么色。类别由 `providerID` 查目录得到。
public struct CategoryShareMember: Equatable, Sendable {
    public var providerID: ProviderID?
    public var displayName: String
    public var colorKey: String
    public var amount: Money

    public init(providerID: ProviderID?, displayName: String, colorKey: String, amount: Money) {
        self.providerID = providerID
        self.displayName = displayName
        self.colorKey = colorKey
        self.amount = amount
    }
}

public struct CategoryShare: Equatable, Sendable {
    public var category: ProviderCategory
    public var amount: Money
    public var fraction: Double
    /// 最大余数法的整数百分比，全段加起来 = 100。
    public var percent: Int
    public var colorKey: String
    public var memberNames: [String]

    public init(
        category: ProviderCategory,
        amount: Money,
        fraction: Double,
        percent: Int,
        colorKey: String,
        memberNames: [String]
    ) {
        self.category = category
        self.amount = amount
        self.fraction = fraction
        self.percent = percent
        self.colorKey = colorKey
        self.memberNames = memberNames
    }
}
