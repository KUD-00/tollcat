import Foundation
import SwiftData
import MeterPersistence

/// 偏好的读写口，持内存副本供热路径读。
///
/// **读**走副本：`rebuildPresentation` 这种每次刷新都跑的路径也要读偏好，
/// 没有副本时一次重算要多好几次落盘往返。
/// **写**永远先读盘再改再存：设置页（外观、提醒）绕过这里直接写同一条记录，
/// 基于副本做读改写会把人家刚写的字段冲掉。写完重读一次，副本和
/// `AppPreferencesRecord.save` 的规范化结果保持一致。
///
/// 绕过这里整库动刀的（清库、迁移导入、演示种子）之后必须调 `reload()`。
@MainActor
final class DashboardPreferences {
    private let container: ModelContainer
    private(set) var current: AppPreferences

    init(container: ModelContainer) {
        self.container = container
        current = Self.load(from: container)
    }

    func reload() {
        current = Self.load(from: container)
    }

    func update(_ mutate: (inout AppPreferences) -> Void) {
        var preferences = Self.load(from: container)
        mutate(&preferences)
        let context = ModelContext(container)
        try? AppPreferencesRecord.save(preferences, to: context)
        reload()
    }

    private static func load(from container: ModelContainer) -> AppPreferences {
        let context = ModelContext(container)
        return (try? AppPreferencesRecord.load(from: context)) ?? .default
    }
}
