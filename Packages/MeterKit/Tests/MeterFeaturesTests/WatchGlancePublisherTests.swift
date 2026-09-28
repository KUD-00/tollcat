import Foundation
import Testing
import MeterGlance
@testable import MeterFeatures

/// 复杂功能那条通道每天只有几十次。只在表盘上看得出变化时才花。
@Suite("手表推送：什么时候花复杂功能的额度")
struct WatchGlancePublisherTests {
    @Test("第一次一定推")
    func firstTime() {
        #expect(WatchGlancePublisher.changesTheFace(from: nil, to: GlanceSamples.month))
    }

    @Test("数没变、只是刷新时间挪了几分钟，不推")
    func sameNumbersLaterRefresh() {
        var next = GlanceSamples.month
        next.lastRefreshAt = next.lastRefreshAt?.addingTimeInterval(15 * 60)
        next.generatedAt = next.generatedAt.addingTimeInterval(15 * 60)
        #expect(!WatchGlancePublisher.changesTheFace(from: GlanceSamples.month, to: next))
    }

    @Test("数变了就推")
    func numbersChanged() {
        #expect(WatchGlancePublisher.changesTheFace(from: GlanceSamples.month, to: GlanceSamples.overBudget))
    }

    /// 手表上那份已经在说「几小时前更新」了，新刷新的数得去把那句话换掉。
    @Test("手表那份已经旧了就推")
    func previousWentStale() throws {
        let previous = GlanceSamples.month
        var next = previous
        let staleAt = try #require(previous.staleAt)
        next.generatedAt = staleAt.addingTimeInterval(60)
        next.lastRefreshAt = next.generatedAt
        #expect(WatchGlancePublisher.changesTheFace(from: previous, to: next))
    }
}
