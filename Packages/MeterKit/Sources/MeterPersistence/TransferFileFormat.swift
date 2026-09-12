import Foundation

/// `.tollcat` 文件的固定头。头里只有密码学参数和过期时间，
/// 不能出现凭据、也不能出现 provider 名字——否则不用解密就能看出用了哪几家。
enum TransferFileFormat: Sendable {
    static let magic = Data("TOLL".utf8)
    static let version: UInt8 = 1
    static let magicByteCount = 4
    static let versionByteCount = 1
    static let saltByteCount = 16
    static let iterationsByteCount = 4
    static let nonceByteCount = 12
    static let notAfterByteCount = 8
    static let tagByteCount = 16

    static let magicOffset = 0
    static let versionOffset = magicByteCount
    static let saltOffset = versionOffset + versionByteCount
    static let iterationsOffset = saltOffset + saltByteCount
    static let nonceOffset = iterationsOffset + iterationsByteCount
    static let notAfterOffset = nonceOffset + nonceByteCount
    static let headerByteCount = notAfterOffset + notAfterByteCount
}
