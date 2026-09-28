import Foundation
import Testing
@testable import MeterGlance

@Suite("一眼：时间线排哪几刻")
struct GlanceTimelineTests {
    @Test("现在、变旧那一刻、之后每小时、跨月")
    func entryDates() throws {
        let glance = GlanceSamples.month
        let now = GlanceSamples.now
        let staleAt = try #require(glance.staleAt)
        let dates = GlanceTimeline.entryDates(for: glance, now: now)
        #expect(dates.first == now)
        #expect(dates.contains(staleAt))
        #expect(dates.contains(staleAt.addingTimeInterval(3600)))
        #expect(dates.last == glance.monthEnd)
        #expect(dates == dates.sorted())
        #expect(Set(dates).count == dates.count)
    }

    @Test("过去的时刻不排")
    func dropsPast() {
        let glance = GlanceSamples.stale
        let now = GlanceSamples.now
        let dates = GlanceTimeline.entryDates(for: glance, now: now)
        #expect(dates.allSatisfy { $0 >= now })
    }

    @Test("没有数就只有现在")
    func nothing() {
        #expect(GlanceTimeline.entryDates(for: nil, now: GlanceSamples.now) == [GlanceSamples.now])
    }
}
