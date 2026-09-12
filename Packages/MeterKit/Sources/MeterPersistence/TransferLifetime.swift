import Foundation

/// 过期只缩小「误发出去」的暴露窗口。拿到文件的人离线爆破根本不看 `notAfter`。
/// 不许把过期写成「所以是安全的」。真正的保护是 10 位码 + PBKDF2 + AES-GCM。
public enum TransferLifetime: Sendable {
    public static let duration: TimeInterval = 24 * 60 * 60

    public static var hourCount: Int {
        Int(duration / 3600)
    }
}
