import Foundation
import Testing
import MeterCore
import MeterDesign
@testable import MeterFeatures
@testable import MeterModules

struct CompositionSlicesTests {
    @Test("5 家及以下不出现其他")
    func fiveOrFewerHasNoOther() {
        let slices = CompositionSlices.make(from: segments(count: 5))
        #expect(slices.count == 5)
        #expect(slices.filter { !$0.mergedNames.isEmpty }.isEmpty)
        #expect(slices.map(\.id) == [
            AccountID.fixture(for: .aws).rawValue.uuidString,
            AccountID.fixture(for: .cloudflare).rawValue.uuidString,
            AccountID.fixture(for: .openai).rawValue.uuidString,
            AccountID.fixture(for: .github).rawValue.uuidString,
            AccountID.fixture(for: .neon).rawValue.uuidString,
        ])
    }

    @Test("超过 5 家时第 5 名之后合并成其他")
    func mergesAfterFifth() {
        let slices = CompositionSlices.make(from: segments(count: 8))
        #expect(slices.count == 6)
        #expect(slices.prefix(5).filter { !$0.mergedNames.isEmpty }.isEmpty)

        let other = slices.last
        #expect(other?.id == "other")
        #expect(other?.name == String(localized: MeterModules.L("其他")))
        #expect(other?.color == MeterColor.compositionOther)
        #expect(other?.mergedNames == ["Vercel", "Anthropic", "Fly"])
        #expect(other?.amountText == Money(usd: 17).formatted())
        #expect(abs((other?.fraction ?? 0) - 0.17) < 0.0001)
    }

    @Test("其他的无障碍标签含被合并的几家")
    func otherSpokenIncludesMembers() {
        let slices = CompositionSlices.make(from: segments(count: 8))
        let spoken = CompositionSlices.spokenOther(from: slices)
        #expect(spoken != nil)
        #expect(spoken?.contains("Vercel") == true)
        #expect(spoken?.contains("Anthropic") == true)
        #expect(spoken?.contains("Fly") == true)
    }

    @Test("刚好 5 家时无障碍不提其他")
    func fiveHasNoSpokenOther() {
        let slices = CompositionSlices.make(from: segments(count: 5))
        #expect(CompositionSlices.spokenOther(from: slices) == nil)
    }

    @Test("构成卡不就地展开，详细页从右侧推进")
    func moduleViewDoesNotExpandInPlace() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MeterFeatures/Dashboard")
        // 模块视图搬去了 MeterModules（widget 才链得到），源码扫描跟着走。
        let modules = root
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "MeterModules")
        let module = try String(
            contentsOf: modules.appending(path: "CompositionModuleView.swift"),
            encoding: .utf8
        )
        let detail = try String(
            contentsOf: root.appending(path: "CompositionDetailView.swift"),
            encoding: .utf8
        )
        let dashboard = try String(
            contentsOf: root.appending(path: "DashboardView.swift"),
            encoding: .utf8
        )
        #expect(!module.contains("isExpanded"))
        #expect(!module.contains(".sheet(isPresented:"))
        // 段行推详情走 DashboardRouteLink：iPhone / iPad 系统栈，Mac 列内手工栈。
        #expect(detail.contains("DashboardRouteLink(route: .account"))
        #expect(detail.contains("DashboardRouteLink(route: .provider"))
        #expect(!detail.contains(".sheet(isPresented:"))
        #expect(dashboard.contains("open(.composition)"))
        #expect(dashboard.contains("path.append(route)"))
        #expect(dashboard.contains("macStack.push("))
        #expect(dashboard.contains("CompositionDetailView"))
    }

    private func segments(count: Int) -> [CompositionSegment] {
        let all: [(ProviderID, String, Double)] = [
            (.aws, "AWS", 32),
            (.cloudflare, "Cloudflare", 18),
            (.openai, "OpenAI", 14),
            (.github, "GitHub", 10),
            (.neon, "Neon", 9),
            (.vercel, "Vercel", 7),
            (.anthropic, "Anthropic", 6),
            (.fly, "Fly", 4),
        ]
        return all.prefix(count).map { id, name, amount in
            CompositionSegment(
                accountID: AccountID.fixture(for: id),
                providerID: id,
                displayName: name,
                colorKey: id.rawValue,
                amount: Money(roundedUSD: amount),
                fraction: amount / 100,
                percent: Int(amount)
            )
        }
    }
}

/// 「含订阅」口径下无主订阅也要占段，饼图才加得回大数字。
struct CompositionBuilderUnattachedSubscriptionTests {
    @Test("挂厂商的订阅给厂商一段（没接账号时），完全不归属的进「手动订阅」段")
    func unattachedSubscriptionsGetTheirOwnSegments() throws {
        let month = MonthToDate(
            totalUSD: Money(usd: 18),
            projectedMonthEndUSD: Money(usd: 18),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [
                Fact(
                    providerID: .aws,
                    accountID: AccountID.fixture(for: .aws),
                    kind: .usage,
                    amountUSD: Money(usd: 10),
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
                Fact(
                    providerID: .openai,
                    accountID: nil,
                    kind: .subscription,
                    amountUSD: Money(usd: 5),
                    confidence: .exact,
                    type: .subscriptionIncluded
                ),
                Fact(
                    providerID: nil,
                    accountID: nil,
                    kind: .subscription,
                    amountUSD: Money(usd: 3),
                    confidence: .exact,
                    type: .subscriptionIncluded
                ),
            ],
            variableUSD: Money(usd: 10),
            subscriptionUSD: Money(usd: 8),
            projectedVariableUSD: Money(usd: 10)
        )
        let content = try #require(CompositionBuilder.make(from: month, connections: []))

        #expect(content.segments.count == 3)
        #expect(content.segments[0].accountID == AccountID.fixture(for: .aws))
        // 厂商没接账号时，这段就叫厂商的名字。
        #expect(content.segments[1].accountID == nil)
        #expect(content.segments[1].providerID == .openai)
        #expect(content.segments[1].displayName == "OpenAI")
        #expect(content.segments[2].accountID == nil)
        #expect(content.segments[2].displayName == String(localized: MeterFeatures.L("手动订阅")))
        // 段的钱加起来就是大数字上那笔。
        let sum = content.segments.reduce(Money.zero) { $0 + $1.amount }
        #expect(sum == month.totalUSD)
        #expect(content.totalText == "$18.00")
    }

    @Test("同一账号的用量和订阅并成一段")
    func accountSubscriptionMergesIntoItsAccountSegment() throws {
        let github = AccountID.fixture(for: .github)
        let month = MonthToDate(
            totalUSD: Money(usd: 14),
            projectedMonthEndUSD: Money(usd: 14),
            confidence: .exact,
            estimatedAccounts: [],
            facts: [
                Fact(
                    providerID: .github,
                    accountID: github,
                    kind: .planAndUsage,
                    amountUSD: Money(usd: 10),
                    confidence: .exact,
                    type: .monthToDateUsage
                ),
                Fact(
                    providerID: .github,
                    accountID: github,
                    kind: .planAndUsage,
                    amountUSD: Money(usd: 4),
                    confidence: .exact,
                    type: .subscriptionIncluded
                ),
            ],
            variableUSD: Money(usd: 10),
            subscriptionUSD: Money(usd: 4),
            projectedVariableUSD: Money(usd: 10)
        )
        let content = try #require(CompositionBuilder.make(from: month, connections: []))

        #expect(content.segments.count == 1)
        #expect(content.segments[0].accountID == github)
        #expect(content.segments[0].amount == Money(usd: 14))
    }
}
