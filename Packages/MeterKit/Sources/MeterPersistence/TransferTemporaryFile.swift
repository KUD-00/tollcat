import Foundation

public enum TransferTemporaryFile: Sendable {
    /// 密文在内存里拼好之后一次性写盘。不要先写明文再加密。
    public static func write(_ bytes: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("toll-\(UUID().uuidString)")
            .appendingPathExtension("tollcat")
        do {
            try bytes.write(to: url, options: .atomic)
        } catch {
            throw TransferExportError.writeFailed
        }
        var mutable = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutable.setResourceValues(values)
        return url
    }

    public static func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// 只删我们自己写的临时文件和系统 Inbox。用户从「文件」里挑的那份不要动。
    ///
    /// 必须是「在这个目录里面」：`contains("/Inbox/")` 会把 iCloud Drive、邮件附件里任何
    /// 叫 Inbox 的文件夹都算进来，导入完就把用户唯一的备份删了；不带 `/` 的前缀比较
    /// 还会放行 tmp 旁边同名前缀的兄弟目录。系统 Open-In 的副本在 tmp 下或 Documents/Inbox。
    public static func shouldDeleteAfterImport(_ url: URL) -> Bool {
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        var roots = [FileManager.default.temporaryDirectory]
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            roots.append(documents.appendingPathComponent("Inbox", isDirectory: true))
        }
        return roots.contains { root in
            var base = root.resolvingSymlinksInPath().standardizedFileURL.path
            while base.count > 1, base.hasSuffix("/") {
                base.removeLast()
            }
            return path.hasPrefix(base + "/")
        }
    }
}
