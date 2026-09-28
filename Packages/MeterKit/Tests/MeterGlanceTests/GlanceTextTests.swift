import Foundation
import Testing
@testable import MeterGlance

@Suite("一眼：手表自己要说的字")
struct GlanceTextTests {
    @Test("一分钟内说刚同步")
    func justSynced() {
        let now = GlanceSamples.now
        let text = GlanceText.synced(now.addingTimeInterval(-10), now: now).map { String(localized: $0) }
        #expect(text == String(localized: L("刚从 iPhone 同步")))
        #expect(GlanceText.synced(nil, now: now) == nil)
    }

    /// 两台设备的钟差几秒，「1 分钟后」是一句不可能的话。
    @Test("钟快了也不说将来时")
    func clampsFuture() {
        let now = GlanceSamples.now
        #expect(GlanceText.relative(now.addingTimeInterval(90), now: now) == GlanceText.relative(now, now: now))
    }
}
