import Foundation
import Testing
@testable import MeterCore

struct VariableComparisonTests {
    @Test("只加从量，订阅再大也不进")
    func ignoresSubscriptions() {
        let comparison = VariableComparison.make(
            from: MonthToDate(
                totalUSD: Money(usd: 40),
                projectedMonthEndUSD: Money(usd: 40),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .aws,
                        accountID: AccountID.fixture(for: .aws),
                        kind: .usage,
                        amountUSD: Money(usd: 20),
                        comparisonUSD: Money(usd: 10),
                        changeRatio: 1,
                        confidence: .exact,
                        type: .monthToDateUsage
                    ),
                    Fact(
                        providerID: .github,
                        accountID: AccountID.fixture(for: .github),
                        kind: .subscription,
                        amountUSD: Money(usd: 20),
                        comparisonUSD: Money(usd: 20),
                        changeRatio: 0,
                        confidence: .exact,
                        type: .subscriptionIncluded
                    ),
                ],
                variableUSD: Money(usd: 40),
                projectedVariableUSD: Money(usd: 40)
            )
        )

        #expect(comparison?.current == Money(usd: 20))
        #expect(comparison?.previous == Money(usd: 10))
        #expect(comparison?.ratio == 1)
    }

    @Test("一家从量缺上月数，本月金额仍进合计，上月只含能比的")
    func missingOneProviderComparesTheRest() {
        let comparison = VariableComparison.make(
            from: MonthToDate(
                totalUSD: Money(usd: 30),
                projectedMonthEndUSD: Money(usd: 30),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .aws,
                        accountID: AccountID.fixture(for: .aws),
                        kind: .usage,
                        amountUSD: Money(usd: 20),
                        comparisonUSD: Money(usd: 10),
                        confidence: .exact,
                        type: .monthToDateUsage
                    ),
                    Fact(
                        providerID: .neon,
                        accountID: AccountID.fixture(for: .neon),
                        kind: .usage,
                        amountUSD: Money(usd: 10),
                        confidence: .exact,
                        type: .monthToDateUsage
                    ),
                ],
                variableUSD: Money(usd: 30),
                projectedVariableUSD: Money(usd: 30)
            )
        )

        #expect(comparison?.current == Money(usd: 30))
        #expect(comparison?.previous == Money(usd: 10))
        #expect(comparison?.ratio == 2)
        #expect(comparison?.comparedCount == 1)
        #expect(comparison?.skippedCount == 1)
        #expect(comparison?.skippedCurrent == Money(usd: 10))
    }

    @Test("没有任何从量就不建")
    func noVariableFactsYieldsNil() {
        let comparison = VariableComparison.make(
            from: MonthToDate(
                totalUSD: Money(usd: 20),
                projectedMonthEndUSD: Money(usd: 20),
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .github,
                        kind: .subscription,
                        amountUSD: Money(usd: 20),
                        comparisonUSD: Money(usd: 20),
                        confidence: .exact,
                        type: .subscriptionIncluded
                    )
                ],
                variableUSD: Money(usd: 20),
                projectedVariableUSD: Money(usd: 20)
            )
        )

        #expect(comparison == nil)
    }
}
