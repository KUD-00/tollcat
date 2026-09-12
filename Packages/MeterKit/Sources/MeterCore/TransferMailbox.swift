import Foundation

/// 迁移包里的读数信箱。
///
/// **必须跟着走,否则换设备是静默失效。** 信箱凭据不属于任何一家 provider，
/// 所以它不在 `connections` 里；不单独带上的话，新设备导入后 Render 那几家
/// 还在列表里、还显示着旧数字，而用户机器上的脚本仍在往老信箱投——
/// 两边都不报错，数字就那么停住了。
public struct TransferMailbox: Codable, Equatable, Sendable {
    public var mailbox: String
    public var readKey: String

    public init(mailbox: String, readKey: String) {
        self.mailbox = mailbox
        self.readKey = readKey
    }
}

extension TransferMailbox: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "TransferMailbox(\(mailbox))" }
    public var debugDescription: String { description }
}
