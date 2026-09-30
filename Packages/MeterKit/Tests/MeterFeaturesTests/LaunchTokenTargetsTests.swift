import Foundation
import MeterCore
import MeterDashboard
import Testing
@testable import MeterFeatures

struct LaunchTokenTargetsTests {
    @Test("设计稿那组：云落到 AWS，对话气泡落到 OpenAI，圆柱落到 Neon")
    func designSample() {
        let slices = make([.aws, .cloudflare, .openai, .github, .neon])
        let targets = LaunchTokenTargets.make(from: slices)
        #expect(targets[.cloud] == id(.aws))
        #expect(targets[.ai] == id(.openai))
        #expect(targets[.database] == id(.neon))
    }

    @Test("同一类只接花得最多的那一家：图例顺序在前的先占")
    func firstOfKindWins() {
        let slices = make([.cloudflare, .aws, .anthropic, .openai])
        let targets = LaunchTokenTargets.make(from: slices)
        #expect(targets[.cloud] == id(.cloudflare))
        #expect(targets[.ai] == id(.anthropic))
        #expect(targets[.database] == nil)
    }

    @Test("「其他」和认不出类别的段不接圆牌")
    func otherAndUnmappedAreSkipped() {
        var slices = make([.github])
        slices.append(CompositionSlice(
            id: CompositionSliceBuilder.otherID,
            displayName: "其他",
            colorKey: CompositionSliceBuilder.otherID,
            amount: Money(usd: 3),
            amountText: "$3.00",
            spokenAmount: "3 美元",
            fraction: 0.1,
            percent: 10,
            isOther: true,
            mergedNames: ["AWS"]
        ))
        #expect(LaunchTokenTargets.make(from: slices).isEmpty)
    }

    @Test("生成的启动画面几何正好三枚圆牌，一类一枚")
    func generatedGeometryCoversEveryKind() {
        let kinds = LaunchPocketGeometry.tokens.map(\.kind)
        #expect(Set(kinds) == Set(LaunchTokenKind.allCases))
        #expect(kinds.count == LaunchTokenKind.allCases.count)
        for token in LaunchPocketGeometry.tokens {
            #expect(token.radius > 0)
            #expect((0...LaunchPocketGeometry.canvas).contains(token.x))
            #expect((0...LaunchPocketGeometry.canvas).contains(token.y))
        }
    }

    private func id(_ provider: ProviderID) -> String {
        AccountID.fixture(for: provider).rawValue.uuidString
    }

    private func make(_ providers: [ProviderID]) -> [CompositionSlice] {
        providers.enumerated().map { index, provider in
            CompositionSlice(
                id: id(provider),
                accountID: AccountID.fixture(for: provider),
                providerID: provider,
                displayName: ProviderIdentity.lookup(provider).displayName,
                colorKey: provider.rawValue,
                amount: Money(usd: Decimal(10 - index)),
                amountText: "",
                spokenAmount: "",
                fraction: 0.1,
                percent: 10
            )
        }
    }
}
