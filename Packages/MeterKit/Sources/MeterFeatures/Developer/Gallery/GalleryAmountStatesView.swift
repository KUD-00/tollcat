#if DEBUG
import SwiftUI
import MeterCore
import MeterDesign
import MeterModules

struct GalleryAmountStatesView: View {
    @State private var amountIndex = 0
    @State private var segmentIndex = 0
    @State private var autoCycles = false
    @State private var donutRevealToken = 0

    var body: some View {
        MeterGroupedList {
            Section {
                MonthToDateModuleView(content: amountContent)
                    .listRowBackground(Color.clear)

                Button(L("换一个数字")) {
                    advanceAmount()
                }
                .accessibilityHint(L("在几组金额之间切换，看数字是滚过去的还是硬切"))

                Toggle(L("自动循环"), isOn: $autoCycles)
                    .accessibilityHint(L("每两秒换一次数字和构成条"))
            } header: {
                Text(L("数字滚动"))
            } footer: {
                Text(L("点一下看数字是滚过去的还是硬切的。"))
            }

            Section {
                CompositionModuleView(content: segmentContent)
                    .listRowBackground(Color.clear)

                Button(L("换一组分段")) {
                    advanceSegments()
                }
                .accessibilityHint(L("在 1 段、2 段、5 段、超过 5 家和一家占满之间切换"))
            } header: {
                Text(L("构成过渡"))
            } footer: {
                Text(L("1 段、2 段、5 段、超过 5 家、一家占满。分段应该滑过去，不是瞬间换。"))
            }

            Section {
                CompositionModuleView(content: Self.segmentCycle[2])
                    .id(donutRevealToken)
                    .listRowBackground(Color.clear)

                Button(L("再转一次")) {
                    donutRevealToken += 1
                }
                .accessibilityHint(L("再看一遍圆环从空转到满"))
            } header: {
                Text(L("圆环进场"))
            } footer: {
                Text(L("从空转到满。切到别的 tab 再回来会再转。刷新只过渡各段。减弱动态效果时直接到位。"))
            }
        }
        .navigationTitle(L("金额"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: autoCycles) {
            guard autoCycles else { return }
            while !Task.isCancelled, autoCycles {
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                if Task.isCancelled || !autoCycles { return }
                advanceAmount()
                advanceSegments()
            }
        }
    }

    private var amountContent: MonthToDateModuleContent {
        let sample = Self.amountCycle[amountIndex]
        return GalleryFixtures.monthToDateContent(
            amount: sample.amount,
            projected: sample.projected,
            confidence: .exact
        )
    }

    private var segmentContent: CompositionModuleContent {
        Self.segmentCycle[segmentIndex]
    }

    private func advanceAmount() {
        amountIndex = (amountIndex + 1) % Self.amountCycle.count
    }

    private func advanceSegments() {
        segmentIndex = (segmentIndex + 1) % Self.segmentCycle.count
    }

    private static let amountCycle: [(amount: Money, projected: Money)] = [
        (Money(roundedUSD: 9.99), Money(usd: 20)),
        (Money(roundedUSD: 67.20), Money(usd: 94)),
        (Money(roundedUSD: 1234.56), Money(usd: 2400)),
        (Money(roundedUSD: 1_234_567.89), Money(usd: 2_000_000)),
        (.zero, .zero),
        (Money(roundedUSD: -12.34), Money(usd: -20)),
    ]

    private static let segmentCycle: [CompositionModuleContent] = [
        GalleryFixtures.composition([(.aws, 1, 100)]),
        GalleryFixtures.composition([
            (.aws, 0.7, 70),
            (.cloudflare, 0.3, 30),
        ]),
        GalleryFixtures.composition([
            (.aws, 0.45, 45),
            (.cloudflare, 0.23, 23),
            (.openai, 0.16, 16),
            (.github, 0.09, 9),
            (.neon, 0.07, 7),
        ]),
        GalleryFixtures.eightProviderComposition,
        GalleryFixtures.composition([(.openai, 1, 100)]),
    ]
}

#Preview("Light") {
    NavigationStack {
        GalleryAmountStatesView()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        GalleryAmountStatesView()
    }
    .preferredColorScheme(.dark)
}
#endif
