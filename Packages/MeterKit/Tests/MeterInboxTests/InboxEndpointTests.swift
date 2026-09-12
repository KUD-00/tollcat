import Foundation
import Testing
import MeterProviders
import MeterTips
@testable import MeterInbox

struct InboxEndpointTests {
    @Test("信箱和打赏共用同一个 Worker origin —— 两边各写一份，这里锁死相等")
    func originMatchesTipWorker() {
        #expect(InboxEndpoint.origin == TipWorkerEndpoint.origin)
    }

    @Test("这个 host 在出站清单里，关于页看得到")
    func hostIsDeclared() {
        let host = InboxEndpoint.origin.host
        #expect(host?.isEmpty == false)
        #expect(OutboundHosts.contains(InboxEndpoint.inboxURL))
        #expect(OutboundHosts.contains(InboxEndpoint.readingsURL))
        #expect(OutboundHosts.contains(InboxEndpoint.ingestKeysURL))
        #expect(OutboundHosts.contains(InboxEndpoint.ingestKeyURL(id: "k1")))
    }

    @Test("三条路径互不相同，且都挂在 /v1 下")
    func pathsAreDistinctAndVersioned() {
        let urls: [URL] = [
            InboxEndpoint.inboxURL,
            InboxEndpoint.ingestKeysURL,
            InboxEndpoint.ingestKeyURL(id: "k1"),
            InboxEndpoint.readingsURL,
        ]
        #expect(Set(urls).count == 4)
        for url in urls {
            #expect(url.path().hasPrefix("/v1/"), "\(url.path()) 没有版本前缀")
            #expect(url.scheme == "https")
        }
    }
}
