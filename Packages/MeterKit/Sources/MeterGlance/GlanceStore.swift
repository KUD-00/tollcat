import Foundation

/// 手表上收到的最后一份 `Glance`，落在 App Group 里一个文件上。
///
/// 手表 App 收、手表小组件读，两个进程之间只有这一个文件。没有数据库：
/// 手表上从来只有「最新那一份」，没有历史可存。
public struct GlanceStore: Sendable {
    /// 和 iPhone 那边是同一个 id（`PersistenceContainer.iOSAppGroupIdentifier`，
    /// 测试核对两者相等）。App Group 是按设备分的容器，手表上这个容器里
    /// 只有这一个文件——账本和凭据从来不在这里。
    public static let appGroupIdentifier = "group.com.zhechengqi.tollcat"

    static let fileName = "glance.json"

    private let fileURL: URL?

    public init(directory: URL?) {
        fileURL = directory?.appending(path: Self.fileName, directoryHint: .notDirectory)
    }

    /// App Group 拿不到（没签名的构建）时退回本进程自己的 Application Support：
    /// 手表 App 自己还看得到，小组件看不到——比两边都空好。
    public static func live() -> GlanceStore {
        let shared = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return GlanceStore(directory: shared ?? fallback)
    }

    public func load() -> Glance? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return GlanceCodec.decode(data)
    }

    /// 比手上那份旧的不收：WatchConnectivity 的几条通道不保证先后，
    /// 晚到的旧推送不能把刚收到的新数盖掉。
    @discardableResult
    public func saveIfNewer(_ glance: Glance) -> Bool {
        if let current = load(), current.generatedAt > glance.generatedAt {
            return false
        }
        guard let fileURL, let data = try? GlanceCodec.encode(glance) else { return false }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            try data.write(to: fileURL, options: [.atomic])
            return true
        } catch {
            return false
        }
    }
}
