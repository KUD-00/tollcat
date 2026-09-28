import Foundation
import Testing
@testable import MeterGlance

@Suite("一眼：载荷编解码")
struct GlanceCodecTests {
    @Test("编码再解码是同一份")
    func roundTrip() throws {
        let data = try GlanceCodec.encode(GlanceSamples.month)
        #expect(GlanceCodec.decode(data) == GlanceSamples.month)
    }

    @Test("字典里取得回来")
    func messageRoundTrip() throws {
        let message = try GlanceCodec.message(GlanceSamples.overBudget)
        #expect(GlanceCodec.glance(in: message) == GlanceSamples.overBudget)
        #expect(GlanceCodec.glance(in: [:]) == nil)
    }

    /// 手表和 iPhone 不一定同时升级。对不上的那份丢掉，不去猜它的意思。
    @Test("格式版本对不上就丢")
    func rejectsOtherSchema() throws {
        var glance = GlanceSamples.month
        glance.schema = Glance.currentSchema + 1
        let data = try GlanceCodec.encode(glance)
        #expect(GlanceCodec.decode(data) == nil)
        #expect(GlanceCodec.decode(Data("not json".utf8)) == nil)
    }

    @Test("只挪了推送时刻不算新消息")
    func sameNewsIgnoresGeneratedAt() {
        var later = GlanceSamples.month
        later.generatedAt = later.generatedAt.addingTimeInterval(600)
        #expect(later.carriesSameNews(as: GlanceSamples.month))
        later.lastRefreshAt = later.lastRefreshAt?.addingTimeInterval(60)
        #expect(!later.carriesSameNews(as: GlanceSamples.month))
    }
}
