import Foundation
import SwiftData

/// 账本那一整份是从什么折出来的。**全库一行。**
///
/// 和账本行同生共死：`deleteAll` 会把它一起删掉，于是"没有戳"必然等于
/// "没有账本"，不存在半边有效的状态。写账本的每条路都必须把戳换成新的——
/// 忘了换的表现是每次打开都白重折一遍（慢，但不会错），比反过来好得多。
@Model
public final class LedgerStampRecord {
    /// 全库一行，主键写死。多出一行只可能是并发写，读的时候取第一行、清掉其余。
    public var id: String
    public var inputDigest: String
    public var day: Date
    public var zone: String

    public init(fingerprint: LedgerFingerprint) {
        self.id = Self.singletonID
        self.inputDigest = fingerprint.inputDigest
        self.day = fingerprint.day
        self.zone = fingerprint.zone
    }

    public static let singletonID = "ledger"

    public var fingerprint: LedgerFingerprint {
        LedgerFingerprint(inputDigest: inputDigest, day: day, zone: zone)
    }

    public func apply(_ fingerprint: LedgerFingerprint) {
        inputDigest = fingerprint.inputDigest
        day = fingerprint.day
        zone = fingerprint.zone
    }
}
