import Foundation

/// 一次接入的主键。同一厂商可以有多个账号。
///
/// 不在本模块生成：`UUID()` 只发生在 Features 的向导保存 / 信箱接入 / 手填用量 / 种子。
public struct AccountID: Hashable, Sendable, Codable, RawRepresentable, Identifiable {
    public let rawValue: UUID
    public var id: UUID { rawValue }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    /// 测试、Preview、夹具用的确定 UUID。byte 15 = `n`。不是运行时生成入口。
    public static func fixture(_ n: UInt8) -> AccountID {
        AccountID(
            rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, n))
        )
    }

    /// 一家厂商一份默认账号，让「一家一行」的旧夹具继续过。
    /// 同厂商第二份必须显式传 `fixture`。
    public static func fixture(for provider: ProviderID) -> AccountID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = 0xA1
        let utf8 = Array(provider.rawValue.utf8)
        for (index, byte) in utf8.enumerated() {
            bytes[index % 16] ^= byte
            bytes[(index &+ 7) % 16] = bytes[(index &+ 7) % 16] &+ byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return AccountID(
            rawValue: UUID(
                uuid: (
                    bytes[0], bytes[1], bytes[2], bytes[3],
                    bytes[4], bytes[5], bytes[6], bytes[7],
                    bytes[8], bytes[9], bytes[10], bytes[11],
                    bytes[12], bytes[13], bytes[14], bytes[15]
                )
            )
        )
    }
}
