import Foundation
import MeterCore
import MeterFormat

/// 一家（厂商）这个月花了多少，拆成按量和订阅两块。
///
/// 服务列表那一行、详情页的大数字、它下面那行「（按量 $11.05 + 订阅 $5.00）」都读这一份。
/// **只从 fact 读**：大数字加起来的就是这些 fact，另算一遍就会和它对不上。
/// 跟随端（Android / Windows）拿桥给的字，不要把几个账号的金额字符串解析回来再加——
/// 那些字已经换成显示货币，而且挂在厂商上的无主订阅不在任何一个账号底下。
public struct VendorSpend: Equatable, Sendable {
    public var providerID: ProviderID
    public var usage: Money
    public var subscription: Money
    /// 真正算进本月的 fact 有几条。0 条时这家没有可以加的数，调用方走自己的兜底。
    public var contributingCount: Int

    public var total: Money { usage + subscription }

    public init(providerID: ProviderID, usage: Money, subscription: Money, contributingCount: Int) {
        self.providerID = providerID
        self.usage = usage
        self.subscription = subscription
        self.contributingCount = contributingCount
    }

    /// 属于这家的 fact：账号在 `accounts` 里的，加上挂在厂商上、没有账号的（无主订阅）。
    public static func facts(
        for providerID: ProviderID,
        accounts: Set<AccountID>,
        in facts: [Fact]
    ) -> [Fact] {
        facts.filter { fact in
            guard fact.providerID == providerID else { return false }
            if let id = fact.accountID {
                return accounts.contains(id)
            }
            return true
        }
    }

    public static func make(
        providerID: ProviderID,
        accounts: Set<AccountID>,
        facts: [Fact]
    ) -> VendorSpend {
        var usage = Money.zero
        var subscription = Money.zero
        var count = 0
        for fact in Self.facts(for: providerID, accounts: accounts, in: facts) {
            guard let amount = fact.amountUSD else { continue }
            switch fact.type {
            case .monthToDateUsage, .prepaidConsumption:
                usage += amount
                count += 1
            case .subscriptionIncluded:
                subscription += amount
                count += 1
            case .subscriptionSuperseded, .freeQuota, .fetchFailed:
                continue
            }
        }
        return VendorSpend(providerID: providerID, usage: usage, subscription: subscription, contributingCount: count)
    }

    /// 「（按量 $11.05 + 订阅 $5.00）」。两块都有钱才出：只有一块时那一块就是大数字本身。
    /// 括号跟着语言走：中日全角，英文半角。
    public func compositionCaption(presentation: MoneyPresentation) -> String? {
        guard usage > .zero, subscription > .zero else { return nil }
        return L("（按量 \(usage.formatted(using: presentation)) + 订阅 \(subscription.formatted(using: presentation))）")
    }
}
