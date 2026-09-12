import Foundation

enum ConnectionWriteMode: Sendable {
    /// 新 UUID 引用，insert afterSiblings。
    case create
    /// 同一 credentialReference，update 指纹 / hint。不换 AccountID。
    case rotate
}
