import Foundation
import Testing
import MeterCore
@testable import MeterFeatures

struct CatSpeechFallbackTests {
    @Test("没有接入时睡觉，说还没有账单")
    func sleepingWithoutProvider() {
        let text = CatSpeechFallback.line(for: prompt(mood: .sleeping, hasAnyProvider: false))
        #expect(text.contains("还没有账单") || text.lowercased().contains("no bill") || text.contains("請求"))
    }

    @Test("正常路径会带上已经格式化的合计")
    func normalUsesPreformattedTotals() {
        var value = prompt(mood: .normal, hasAnyProvider: true)
        value.totalText = "$47.20"
        value.projectedText = "$94.00"
        let text = CatSpeechFallback.line(for: value)
        #expect(text.contains("$47.20"))
        #expect(text.contains("$94.00"))
    }

    @Test("省到了用已经算好的百分比，不在句子里现算")
    func savedUsesPrecomputedPercent() {
        var value = prompt(mood: .saved, hasAnyProvider: true)
        value.changePercent = -18
        let text = CatSpeechFallback.line(for: value)
        #expect(text.contains("18"))
    }

    @Test("候选句第 0 条就是现在的兜底句")
    func firstCandidateMatchesLegacyLine() {
        var value = prompt(mood: .normal, hasAnyProvider: true)
        value.totalText = "$47.20"
        value.projectedText = "$94.00"
        let candidates = CatSpeechFallback.candidates(for: value)
        #expect(candidates[0].text == CatSpeechFallback.line(for: value))
        #expect(candidates[0].text.contains("$47.20"))
        #expect(candidates[0].text.contains("$94.00"))
    }

    private func prompt(mood: CatMood, hasAnyProvider: Bool) -> CatSpeechPrompt {
        CatSpeechPrompt(
            locale: Locale(identifier: "zh_Hans"),
            mood: mood,
            hasAnyProvider: hasAnyProvider,
            totalText: "$0.00",
            projectedText: "$0.00",
            changePercent: nil,
            leadAnomalyName: nil,
            leadAnomalyPercent: nil,
            leadBalanceName: nil
        )
    }
}
