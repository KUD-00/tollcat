import Foundation
import Testing
import MeterProviders
import MeterTips
@testable import MeterPersistence

struct CatalogEndpointTests {
    @Test("目录和打赏共用同一个 Worker origin")
    func originMatchesTipWorker() {
        #expect(CatalogEndpoint.origin == TipWorkerEndpoint.origin)
    }

    @Test("目录走 /v1/catalog，https，host 在出站清单里")
    func catalogPathIsStable() {
        let url = CatalogEndpoint.catalogURL
        #expect(url.scheme == "https")
        #expect(url.host == "api.tollcat.app")
        #expect(url.path == "/v1/catalog")
        #expect(OutboundHosts.contains(url))
        #expect(url != TipWorkerEndpoint.tipURL)
    }
}
