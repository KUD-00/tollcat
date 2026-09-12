import Foundation
import Testing
@testable import MeterCore

struct CatMoodResolverTests {
    @Test("dead：合计相对上月同期涨了 100% 以上")
    func deadWhenIncreaseExceedsDouble() {
        let mood = CatMoodResolver.mood(
            for: month(changeRatio: 1.01, total: 40.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: true,
            hasAnomaly: true,
            hasStaleData: true
        )
        #expect(mood == .dead)
    }

    @Test("shocked：涨幅 50% 到 100%，含两端")
    func shockedWhenIncreaseIsBetweenHalfAndDouble() {
        let lower = CatMoodResolver.mood(
            for: month(changeRatio: 0.50, total: 30, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: true,
            hasAnomaly: true,
            hasStaleData: true
        )
        let upper = CatMoodResolver.mood(
            for: month(changeRatio: 1.0, total: 40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        #expect(lower == .shocked)
        #expect(upper == .shocked)
    }

    @Test("alert：有余额告急或有异常项")
    func alertWhenBalanceOrAnomaly() {
        let balance = CatMoodResolver.mood(
            for: month(changeRatio: 0.12, total: 22.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: true,
            hasAnomaly: false,
            hasStaleData: true
        )
        let anomaly = CatMoodResolver.mood(
            for: month(changeRatio: 0.12, total: 22.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: true,
            hasStaleData: false
        )
        #expect(balance == .alert)
        #expect(anomaly == .alert)
    }

    @Test("sleeping：没有已接入 provider，或这次没读到任何数据")
    func sleepingWhenNoProviderOrNoData() {
        let none = CatMoodResolver.mood(
            for: nil,
            hasAnyProvider: false,
            hasAnyReadableData: false,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        let connectedButEmpty = CatMoodResolver.mood(
            for: nil,
            hasAnyProvider: true,
            hasAnyReadableData: false,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        let noReadable = CatMoodResolver.mood(
            for: month(changeRatio: nil, total: 0, comparison: nil, facts: [
                Fact(
                    providerID: .aws,
                    kind: .usage,
                    confidence: .partial,
                    type: .fetchFailed
                ),
            ]),
            hasAnyProvider: true,
            hasAnyReadableData: false,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: true
        )
        #expect(none == .sleeping)
        #expect(connectedButEmpty == .sleeping)
        #expect(noReadable == .sleeping)
    }

    @Test("awkward：有 provider 取数失败，显示的是陈旧数据")
    func awkwardWhenShowingStaleData() {
        let mood = CatMoodResolver.mood(
            for: month(changeRatio: 0.12, total: 22.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: true
        )
        #expect(mood == .awkward)
    }

    @Test("saved：比上月同期少，或全部在免费额度内")
    func savedWhenDownOrEntirelyFree() {
        let cheaper = CatMoodResolver.mood(
            for: month(changeRatio: -0.18, total: 16.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        let free = CatMoodResolver.mood(
            for: MonthToDate(
                totalUSD: .zero,
                projectedMonthEndUSD: .zero,
                confidence: .exact,
                estimatedAccounts: [],
                facts: [
                    Fact(
                        providerID: .vercel,
                        kind: .freeTier,
                        freeQuotaUsedRatio: 0.34,
                        confidence: .exact,
                        type: .freeQuota
                    ),
                ],
                variableUSD: .zero,
                projectedVariableUSD: .zero
            ),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        #expect(cheaper == .saved)
        #expect(free == .saved)
    }

    @Test("normal：其余")
    func normalOtherwise() {
        let mood = CatMoodResolver.mood(
            for: month(changeRatio: 0.12, total: 22.40, comparison: 20),
            hasAnyProvider: true,
            hasAnyReadableData: true,
            hasBalanceAlert: false,
            hasAnomaly: false,
            hasStaleData: false
        )
        #expect(mood == .normal)
    }

    private func month(
        changeRatio: Double?,
        total: Decimal,
        comparison: Decimal?,
        facts: [Fact]? = nil
    ) -> MonthToDate {
        MonthToDate(
            totalUSD: Money(usd: total),
            projectedMonthEndUSD: Money(usd: total * 2),
            confidence: .exact,
            estimatedAccounts: [],
            facts: facts ?? [
                Fact(
                    providerID: .aws,
                    kind: .usage,
                    amountUSD: Money(usd: total),
                    comparisonUSD: comparison.map(Money.init(usd:)),
                    changeRatio: changeRatio,
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
            ],
            comparisonUSD: comparison.map(Money.init(usd:)),
            changeRatio: changeRatio,
            variableUSD: Money(usd: total),
            projectedVariableUSD: Money(usd: total * 2)
        )
    }
}
