import SwiftUI
import Testing
import MeterDesign
@testable import MeterGlance

/// 手表链不了 MeterDesign，颜色在 `GlanceStyle` 里另列了一份。这里逐个核对两边是同一种。
@Suite("一眼：颜色和 App 同一套")
struct GlanceStyleTests {
    @Test("名次色就是构成图的那几种")
    func rankColorsMatchComposition() {
        #expect(GlanceStyle.rankColors.count == MeterColor.compositionNamedLimit)
        for (index, color) in GlanceStyle.rankColors.enumerated() {
            #expect(color == MeterColor.composition(index: index))
        }
        #expect(GlanceStyle.remainderColor == MeterColor.compositionOther)
    }

    @Test("预算三档就是语义色")
    func budgetLevels() {
        #expect(GlanceStyle.color(for: .normal) == MeterColor.good)
        #expect(GlanceStyle.color(for: .close) == MeterColor.warn)
        #expect(GlanceStyle.color(for: .over) == MeterColor.crit)
    }
}
