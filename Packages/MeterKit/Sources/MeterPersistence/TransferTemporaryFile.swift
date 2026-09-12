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
    public static func shouldDeleteAfterImport(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let temporary = FileManager.default.temporaryDirectory.standardizedFileURL.path
        if path.hasPrefix(temporary) {
            return true
        }
        if path.contains("/Inbox/") {
            return true
        }
        return false
    }
}
