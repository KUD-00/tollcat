import Foundation

/// 先算好再交给展示层措辞。领域层只出结构化事实，不出中文句子。
///
/// 只带结构化字段。拼中文句子是展示层和 prompt 构造层的事。
public struct Fact: Hashable, Sendable {
    public var providerID: ProviderID?
    /// 来自 Snapshot 组的 fact 一定有值；无主手动订阅为 nil。
    public var accountID: AccountID?
    public var kind: ProviderKind?
    public var amountUSD: Money?
    public var comparisonUSD: Money?
    public var changeRatio: Double?
    public var freeQuotaUsedRatio: Double?
    public var confidence: Confidence
    public var type: FactKind

    public init(
        providerID: ProviderID? = nil,
        accountID: AccountID? = nil,
        kind: ProviderKind? = nil,
        amountUSD: Money? = nil,
        comparisonUSD: Money? = nil,
        changeRatio: Double? = nil,
        freeQuotaUsedRatio: Double? = nil,
        confidence: Confidence,
        type: FactKind
    ) {
        self.providerID = providerID
        self.accountID = accountID
        self.kind = kind
        self.amountUSD = amountUSD
        self.comparisonUSD = comparisonUSD
        self.changeRatio = changeRatio
        self.freeQuotaUsedRatio = freeQuotaUsedRatio
        self.confidence = confidence
        self.type = type
    }
}

extension FactKind {
    /// 这类 fact 记不记入总数。构成条和「上月同期」聚合都以此为准。
    public var contributesToTotal: Bool {
        switch self {
        case .monthToDateUsage, .prepaidConsumption, .subscriptionIncluded:
            return true
        case .subscriptionSuperseded, .freeQuota, .fetchFailed:
            return false
        }
    }
}

/// 「上月同期」的聚合规则只写一份。
///
/// 本月金额**全进**——缺同期的那几家也是这个月花出去的钱，柱和涨跌幅
/// 都要看得见。上月只加两边都有数的，缺的不当 $0：行上不编百分比，
/// 分母也不被「没有的那段历史」拉成零。
///
/// 一家都对比不了时返回 nil：没有分母，涨跌幅就是「还不能对比」。
enum FactComparisonAggregate {
    struct Totals: Equatable, Sendable {
        var current: Money
        var previous: Money
        var comparedCount: Int
        var skippedCount: Int
        var skippedCurrent: Money
    }

    static func totals(
        facts: [Fact],
        including kinds: Set<FactKind>
    ) -> Totals? {
        var current = Money.zero
        var previous = Money.zero
        var comparedCount = 0
        var skippedCount = 0
        var skippedCurrent = Money.zero
        for fact in facts where kinds.contains(fact.type) {
            guard let amount = fact.amountUSD else { continue }
            current += amount
            if let comparison = fact.comparisonUSD {
                previous += comparison
                comparedCount += 1
            } else if amount > .zero {
                skippedCount += 1
                skippedCurrent += amount
            }
        }
        guard comparedCount > 0 else { return nil }
        return Totals(
            current: current,
            previous: previous,
            comparedCount: comparedCount,
            skippedCount: skippedCount,
            skippedCurrent: skippedCurrent
        )
    }
}
