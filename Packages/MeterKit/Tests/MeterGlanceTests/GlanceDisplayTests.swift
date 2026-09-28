import Foundation
import Testing
@testable import MeterGlance

@Suite("一眼：某一刻该说哪句话")
struct GlanceDisplayTests {
    private let now = GlanceSamples.now

    @Test("没收到过就说去 iPhone 上打开")
    func neverSynced() {
        #expect(GlanceDisplay.resolve(nil, now: now) == .neverSynced)
    }

    @Test("新鲜的数照常说")
    func freshMonth() {
        guard case let .month(_, staleSince) = GlanceDisplay.resolve(GlanceSamples.month, now: now) else {
            Issue.record("应该是本月")
            return
        }
        #expect(staleSince == nil)
    }

    @Test("三小时没刷新就把刷新时间说出来")
    func staleAfterThreeHours() throws {
        let glance = GlanceSamples.month
        let refreshed = try #require(glance.lastRefreshAt)
        let justBefore = refreshed.addingTimeInterval(Glance.staleAfter - 1)
        let justAfter = refreshed.addingTimeInterval(Glance.staleAfter)
        guard case let .month(_, before) = GlanceDisplay.resolve(glance, now: justBefore),
              case let .month(_, after) = GlanceDisplay.resolve(glance, now: justAfter)
        else {
            Issue.record("应该是本月")
            return
        }
        #expect(before == nil)
        #expect(after == refreshed)
    }

    /// 10 月 1 日的表盘不能拿 9 月的合计配「本月」两个字。
    @Test("跨过月底就不再说本月")
    func crossingMonthEnd() {
        let glance = GlanceSamples.month
        #expect(GlanceDisplay.resolve(glance, now: glance.monthEnd) == .waitingForMonth)
        #expect(GlanceDisplay.resolve(glance, now: glance.monthEnd.addingTimeInterval(-1)) != .waitingForMonth)
    }

    @Test("没有账单和等本月是两句话")
    func emptyStates() {
        #expect(GlanceDisplay.resolve(GlanceSamples.noBills, now: now) == .noBills)
        var waiting = GlanceSamples.month
        waiting.content = .waitingForMonth
        #expect(GlanceDisplay.resolve(waiting, now: now) == .waitingForMonth)
    }
}
