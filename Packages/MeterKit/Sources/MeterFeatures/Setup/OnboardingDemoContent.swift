import Foundation
import MeterCore
import MeterProviders
import MeterModules

/// 开场预览用的设计稿数字。SPEC 第 04 节那组：从量 43.20、订阅 4.00、合计 47.20。
/// 不是运行时取数。按新用户的默认口径（仅从量）摆：大数字 43.20，
/// 订阅那行不出现，构成里没有订阅段——和第一次打开仪表盘看到的一致。
enum OnboardingDemoContent {
    static let variableUSD = Money(roundedUSD: 43.20)
    static let subscriptionUSD = Money(roundedUSD: 4.00)
    static let projectedVariableUSD = Money(usd: 90)

    static let usage: [(ProviderID, Money)] = [
        (.aws, Money(roundedUSD: 21.40)),
        (.cloudflare, Money(roundedUSD: 11.05)),
        (.openai, Money(roundedUSD: 7.62)),
        (.neon, Money(roundedUSD: 3.13)),
    ]

    static let addPreviewIDs: [ProviderID] = [.aws, .cloudflare, .openai, .github]

    static func monthToDate() -> MonthToDate {
        let usageFacts: [Fact] = usage.map { id, amount in
            Fact(
                providerID: id,
                accountID: AccountID.fixture(for: id),
                kind: id == .openai ? .prepaid : .usage,
                amountUSD: amount,
                confidence: .exact,
                type: id == .openai ? .prepaidConsumption : .monthToDateUsage
            )
        }
        // 默认口径不含订阅：没有 subscriptionIncluded fact（真算的时候
        // 计算器也不会发），totalUSD 就等于从量。订阅金额单独带着，
        // 切换还在；默认按量，那行括号不出现。
        return MonthToDate(
            totalUSD: variableUSD,
            projectedMonthEndUSD: projectedVariableUSD,
            confidence: .exact,
            estimatedAccounts: [],
            facts: usageFacts,
            filter: DashboardFilter(includesSubscriptions: false),
            variableUSD: variableUSD,
            subscriptionUSD: subscriptionUSD,
            projectedVariableUSD: projectedVariableUSD,
            subscriptionAccountIDs: [AccountID.fixture(for: .github)]
        )
    }

    static func monthToDateModule(presentation: MoneyPresentation) -> MonthToDateModuleContent {
        MonthToDateModuleContent.make(
            from: monthToDate(),
            estimatedNames: [],
            staleCaption: nil,
            now: MeterClock.design.now,
            calendar: MeterClock.design.calendar,
            presentation: presentation
        )
    }

    static func composition(presentation: MoneyPresentation) -> CompositionModuleContent? {
        CompositionBuilder.make(
            from: monthToDate(),
            connections: [],
            presentation: presentation
        )
    }
}
