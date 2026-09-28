import Foundation
import Testing
import MeterPersistence
@testable import MeterGlance

@Suite("一眼：手表上的那个文件")
struct GlanceStoreTests {
    private func temporaryStore() -> GlanceStore {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "glance-\(UUID().uuidString)", directoryHint: .isDirectory)
        return GlanceStore(directory: directory)
    }

    @Test("存了读得回来")
    func saveAndLoad() {
        let store = temporaryStore()
        #expect(store.load() == nil)
        #expect(store.saveIfNewer(GlanceSamples.month))
        #expect(store.load() == GlanceSamples.month)
    }

    /// WatchConnectivity 的几条通道不保证先后。
    @Test("晚到的旧推送不盖新数")
    func keepsNewer() {
        let store = temporaryStore()
        var newer = GlanceSamples.overBudget
        newer.generatedAt = GlanceSamples.month.generatedAt.addingTimeInterval(60)
        #expect(store.saveIfNewer(newer))
        #expect(!store.saveIfNewer(GlanceSamples.month))
        #expect(store.load() == newer)
    }

    @Test("App Group 和 iPhone 那边是同一个 id")
    func appGroupMatchesPhone() {
        #expect(GlanceStore.appGroupIdentifier == PersistenceContainer.iOSAppGroupIdentifier)
    }
}
