#if DEBUG
import Testing
@testable import MeterFeatures

@MainActor
struct DeveloperDebugLogTests {
    @Test("复制全部日志含事件和当前 Snapshot")
    func exportIncludesEventsAndStore() {
        DeveloperDebugLog.clear()
        DeveloperDebugLog.record(category: "refresh", "fetch start cloudflare")
        let text = DeveloperDebugLog.exportText(dashboard: .preview, exchanges: [])
        #expect(text.contains("[refresh] fetch start cloudflare"))
        #expect(text.contains("## store"))
        #expect(text.contains("cloudflare"))
    }

    @Test("清空后事件不再出现")
    func clearDropsEvents() {
        DeveloperDebugLog.record(category: "refresh", "temporary")
        DeveloperDebugLog.clear()
        let text = DeveloperDebugLog.exportText(dashboard: .preview, exchanges: [])
        #expect(!text.contains("temporary"))
    }
}
#endif
