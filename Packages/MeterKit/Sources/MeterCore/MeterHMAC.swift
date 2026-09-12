import Foundation

/// HMAC（RFC 2104）。摘要来自 `MeterDigest`，同样是为了让 `MeterProviders`
/// 能为 Android 交叉编译——理由见 `MeterDigest` 的注释。
public enum MeterHMAC: Sendable {
    public static func md5(key: Data, message: Data) -> Data {
        code(key: key, message: message, blockSize: 64, hash: MeterDigest.md5)
    }

    public static func sha1(key: Data, message: Data) -> Data {
        code(key: key, message: message, blockSize: 64, hash: MeterDigest.sha1)
    }

    public static func sha256(key: Data, message: Data) -> Data {
        code(key: key, message: message, blockSize: 64, hash: MeterDigest.sha256)
    }

    /// SHA-384 的块长是 128（跟 SHA-512 走），不是 64。写错了签名全错。
    public static func sha384(key: Data, message: Data) -> Data {
        code(key: key, message: message, blockSize: 128, hash: MeterDigest.sha384)
    }

    private static func code(
        key: Data,
        message: Data,
        blockSize: Int,
        hash: (Data) -> Data
    ) -> Data {
        var block = key.count > blockSize ? hash(key) : key
        if block.count < blockSize {
            block.append(contentsOf: [UInt8](repeating: 0, count: blockSize - block.count))
        }
        var inner = Data(block.map { $0 ^ 0x36 })
        var outer = Data(block.map { $0 ^ 0x5c })
        inner.append(message)
        outer.append(hash(inner))
        return hash(outer)
    }
}
