#if DEBUG
import Foundation
import MeterCore
import MeterPersistence
import MeterProviders
import MeterModules

/// 画廊只用这些值对象。不要 new DashboardModel，也不要碰真实 store。
enum GalleryFixtures {
    static let clock = MeterClock.design

    static func monthToDateContent(
        amount: Money,
        projected: Money = Money(usd: 94),
        confidence: Confidence,
        estimatedNames: [String] = [],
        staleCaption: String? = nil
    ) -> MonthToDateModuleContent {
        MonthToDateModuleContent.make(
            from: MonthToDate(
                totalUSD: amount,
                projectedMonthEndUSD: projected,
                confidence: confidence,
                estimatedAccounts: [],
                facts: [],
                variableUSD: amount,
                projectedVariableUSD: projected
            ),
            estimatedNames: estimatedNames,
            staleCaption: staleCaption,
            now: clock.now,
            calendar: clock.calendar
        )
    }

    static func composition(
        _ items: [(ProviderID, Double, Int)]
    ) -> CompositionModuleContent {
        let segments = items.map { id, fraction, percent in
            let descriptor = ProviderCatalog.descriptor(id: id)
            return CompositionSegment(
                accountID: AccountID.fixture(for: id),
                providerID: id,
                displayName: descriptor?.displayName ?? id.rawValue,
                colorKey: descriptor?.colorKey ?? id.rawValue,
                amount: Money(usd: Decimal(fraction) * 100),
                fraction: fraction,
                percent: percent
            )
        }
        let leader = segments.first
        let total = segments.reduce(Money.zero) { $0 + $1.amount }
        return CompositionModuleContent(
            segments: segments,
            totalText: total.formatted(),
            spokenTotal: SpokenMoney.label(for: total),
            destination: leader?.accountID
        )
    }

    static let comparisonComplete = comparison(
        facts: [
            (.aws, Money(roundedUSD: 21.40), Money(roundedUSD: 13.20)),
            (.cloudflare, Money(roundedUSD: 11.05), Money(roundedUSD: 58.40)),
        ]
    )

    static let comparisonPartial = comparison(
        facts: [
            (.aws, Money(roundedUSD: 21.40), Money(roundedUSD: 13.20)),
            (.neon, Money(roundedUSD: 3.13), nil),
        ],
        sublines: [
            .account(AccountID.fixture(for: .aws)): [
                SpendSubline(
                    id: "EC2",
                    title: "EC2",
                    amountCaption: "$12.10",
                    spokenLabel: "EC2 较上月同期上升百分之 73，本月 $12.10 · 7 月同期 $7.00",
                    comparisonSubtitle: "本月 $12.10 · 7 月同期 $7.00",
                    changeCaption: "+73%",
                    changeRatio: 0.73
                ),
                SpendSubline(
                    id: "S3",
                    title: "S3",
                    amountCaption: "$6.30",
                    spokenLabel: "S3，6 美元 30 美分"
                ),
            ],
        ]
    )

    static let comparisonUnknown = comparison(
        facts: [
            (.neon, Money(roundedUSD: 3.13), nil),
        ]
    )

    static func comparison(
        facts: [(ProviderID, Money, Money?)],
        sublines: [SpendAttribution: [SpendSubline]] = [:]
    ) -> ComparisonModuleContent {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var windowStart = DateComponents()
        windowStart.year = 2026
        windowStart.month = 7
        windowStart.day = 1
        let start = calendar.date(from: windowStart) ?? clock.now
        let domainFacts = facts.map { id, current, previous in
            Fact(
                providerID: id,
                accountID: AccountID.fixture(for: id),
                kind: .usage,
                amountUSD: current,
                comparisonUSD: previous,
                changeRatio: ChangeRatio.compute(current: current, previous: previous),
                confidence: .exact,
                type: .monthToDateUsage
            )
        }
        let variable = facts.reduce(Money.zero) { $0 + $1.1 }
        return ComparisonBuilder.make(
            from: MonthToDate(
                totalUSD: variable,
                projectedMonthEndUSD: variable,
                confidence: .exact,
                estimatedAccounts: [],
                facts: domainFacts,
                comparisonWindow: ComparisonWindow(start: start, end: start, dayOfMonth: 16),
                variableUSD: variable,
                projectedVariableUSD: variable
            ),
            calendar: calendar,
            sublines: sublines
        )
    }

    static let eightProviderComposition = composition([
        (.aws, 0.32, 32),
        (.cloudflare, 0.18, 18),
        (.openai, 0.14, 14),
        (.github, 0.10, 10),
        (.neon, 0.09, 9),
        (.vercel, 0.07, 7),
        (.anthropic, 0.06, 6),
        (.fly, 0.04, 4),
    ])

    static func anomaly(_ names: [(ProviderID, Double)]) -> AnomalyModuleContent {
        AnomalyModuleContent(
            items: names.map { id, ratio in
                let descriptor = ProviderCatalog.descriptor(id: id)
                return AnomalyItem(
                    accountID: AccountID.fixture(for: id),
                    providerID: id,
                    displayName: descriptor?.displayName ?? id.rawValue,
                    colorKey: descriptor?.colorKey ?? id.rawValue,
                    changeRatio: ratio,
                    comparisonUSD: Money(roundedUSD: 13.20),
                    comparisonMonth: 7
                )
            }
        )
    }

    static let verified = SetupVerifyOutcome.success(
        title: String(localized: L("本周期至今 $11.05")),
        detail: String(localized: L("周期 8/1 – 8/31 · 日粒度可用"))
    )

    static let unauthorized = SetupVerifyOutcome.http(
        ErrorCase(
            httpStatus: 401,
            explanation: String(localized: L("这个 token 无效，或者已经被撤销了。")),
            nextStep: String(localized: L("回上一步重新创建一把，创建后立刻复制——它只显示一次。"))
        )
    )

    static let forbidden = SetupVerifyOutcome.http(
        ErrorCase(
            httpStatus: 403,
            explanation: String(localized: L("这个 token 缺 Billing:Read 权限，所以读不到账单。")),
            nextStep: String(localized: L("回上一步按 Custom token 重建，只勾 Account · Billing · Read，不要给任何 Edit。"))
        )
    )

    /// 构造一遍全部画廊模型，给隔离测试用。
    static func constructAll() -> Int {
        var count = 0
        count += [
            monthToDateContent(amount: .zero, confidence: .exact),
            monthToDateContent(amount: Money(roundedUSD: 9.99), confidence: .exact),
            monthToDateContent(amount: Money(roundedUSD: 1234.56), confidence: .estimated),
            monthToDateContent(amount: Money(roundedUSD: 1_234_567.89), confidence: .partial),
            monthToDateContent(amount: Money(roundedUSD: -12.34), confidence: .exact),
        ].count
        count += [
            composition([(.aws, 1, 100)]),
            composition([(.aws, 0.7, 70), (.cloudflare, 0.3, 30)]),
            composition([
                (.aws, 0.45, 45),
                (.cloudflare, 0.23, 23),
                (.openai, 0.16, 16),
                (.github, 0.09, 9),
                (.neon, 0.07, 7),
            ]),
            eightProviderComposition,
        ].count
        count += [anomaly([]), anomaly([(.aws, 0.62)]), anomaly([
            (.aws, 0.62),
            (.openai, 0.41),
            (.cloudflare, 0.33),
            (.neon, 0.28),
        ])].count
        count += [comparisonComplete, comparisonPartial, comparisonUnknown].count
        count += [verified, unauthorized, forbidden, .network, .emptyReading].count
        return count
    }
}
#endif
