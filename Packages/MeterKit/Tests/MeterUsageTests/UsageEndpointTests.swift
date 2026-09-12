import Foundation
import Testing
import MeterInbox
import MeterPersistence
import MeterTips
import MeterFeedback
import MeterUsage
import MeterProviders

struct UsageEndpointTests {
    @Test("匿名计数和其余叶子指向同一个 origin")
    func originMatchesOtherLeaves() {
        #expect(UsageEndpoint.origin == TipWorkerEndpoint.origin)
        #expect(UsageEndpoint.origin == InboxEndpoint.origin)
        #expect(UsageEndpoint.origin == CatalogEndpoint.origin)
        #expect(UsageEndpoint.origin == FeedbackEndpoint.origin)
    }

    @Test("计数走 /v1/usage，https，host 在出站清单里")
    func usagePathIsStable() {
        let url = UsageEndpoint.usageURL
        #expect(url.scheme == "https")
        #expect(url.host == "api.tollcat.app")
        #expect(url.path == "/v1/usage")
        #expect(OutboundHosts.contains(url))
        #expect(url != TipWorkerEndpoint.tipURL)
        #expect(url != FeedbackEndpoint.feedbackURL)
        #expect(url != CatalogEndpoint.catalogURL)
    }
}
