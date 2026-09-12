import Foundation
import MeterCore

/// 猫的表情和台词。输入全是值，输出经 `apply` 回给持有者。
/// 台词从写死的候选里按顺序取第一条——没有模型参与，同一份账单每次说同一句。
@MainActor
final class CatPresenter {
    struct Input {
        var monthToDate: MonthToDate?
        var hasAnyProvider: Bool
        var hasStaleData: Bool
        var runways: [PrepaidRunway]
        var presentation: MoneyPresentation
    }

    func present(_ input: Input, apply: @MainActor (CatMood, String) -> Void) {
        let hasReadable = input.monthToDate.map(CatMoodResolver.hasReadableData(in:)) ?? false
        let hasAnomaly = input.monthToDate.map(CatMoodResolver.hasAnomaly(in:)) ?? false
        let hasBalance = CatMoodResolver.hasBalanceAlert(in: input.runways)

        let mood = CatMoodResolver.mood(
            for: input.monthToDate,
            hasAnyProvider: input.hasAnyProvider,
            hasAnyReadableData: hasReadable,
            hasBalanceAlert: hasBalance,
            hasAnomaly: hasAnomaly,
            hasStaleData: input.hasStaleData
        )

        let prompt = CatSpeechFacts.make(
            from: input.monthToDate,
            mood: mood,
            hasAnyProvider: input.hasAnyProvider,
            runways: input.runways,
            presentation: input.presentation
        )
        apply(mood, CatSpeechFallback.candidates(for: prompt).first?.text ?? "")
    }
}
