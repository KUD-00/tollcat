import Foundation

/// iOS 走 SPM `Bundle.module`。Android 上 ART 的可执行文件不是这份 .so，
/// `Bundle.module` 找不到旁边的 resource bundle，JNI 把解压后的目录指过来。
public enum ProviderResourceLocator: Sendable {
    private final class Box: @unchecked Sendable {
        let lock = NSLock()
        var url: URL?
    }

    private static let box = Box()

    public static func setOverrideDirectory(_ url: URL?) {
        box.lock.lock()
        box.url = url
        box.lock.unlock()
    }

    static var overrideDirectory: URL? {
        box.lock.lock()
        defer { box.lock.unlock() }
        return box.url
    }

    static func url(
        forResource name: String,
        withExtension ext: String,
        subdirectory: String? = nil
    ) -> URL? {
        if let root = overrideDirectory {
            for candidate in fileCandidates(
                root: root,
                name: name,
                ext: ext,
                subdirectory: subdirectory
            ) where FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            // 指了目录就以它为准。Android 上 `Bundle.module` 找不到旁边的资源包时
            // 不是返回 nil 而是直接 fatalError：目录里没有这家的 fixture（offered 远多于
            // 有设计稿的家）会把整个进程带崩，而不是像 iOS 那样静默跳过。
            return nil
        }

        let bundle = Bundle.module
        if let subdirectory,
           let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
        {
            return url
        }
        return bundle.url(forResource: name, withExtension: ext)
    }

    private static func fileCandidates(
        root: URL,
        name: String,
        ext: String,
        subdirectory: String?
    ) -> [URL] {
        let fileName = "\(name).\(ext)"
        var urls: [URL] = []
        if let subdirectory {
            urls.append(root.appendingPathComponent(subdirectory).appendingPathComponent(fileName))
            if subdirectory.hasPrefix("Fixtures/") {
                let stripped = String(subdirectory.dropFirst("Fixtures/".count))
                urls.append(root.appendingPathComponent(stripped).appendingPathComponent(fileName))
            }
        }
        urls.append(root.appendingPathComponent(fileName))
        return urls
    }
}
