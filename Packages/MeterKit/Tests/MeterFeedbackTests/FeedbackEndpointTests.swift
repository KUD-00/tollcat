import Foundation
import Testing
import MeterFeedback
import MeterInbox
import MeterPersistence
import MeterTips
import MeterUsage

struct FeedbackEndpointTests {
    /// 一个 Worker 承担全部 endpoint。五个模块不能互相 import，
    /// 所以「同一个 origin」这件事只能在测试里锁。
    @Test("反馈、打赏、读数信箱、目录、匿名计数指向同一个 origin")
    func allWorkerModulesShareOneOrigin() {
        #expect(FeedbackEndpoint.origin == TipWorkerEndpoint.origin)
        #expect(FeedbackEndpoint.origin == InboxEndpoint.origin)
        #expect(FeedbackEndpoint.origin == CatalogEndpoint.origin)
        #expect(FeedbackEndpoint.origin == UsageEndpoint.origin)
    }

    @Test("反馈走 /v1/feedback，而且是 https")
    func feedbackPathIsStable() throws {
        let url = FeedbackEndpoint.feedbackURL
        #expect(url.scheme == "https")
        #expect(url.host == "api.tollcat.app")
        #expect(url.path == "/v1/feedback")
        // 和打赏那条不能撞：撞了会把反馈写进 tips 表。
        #expect(url != TipWorkerEndpoint.tipURL)
    }
}
