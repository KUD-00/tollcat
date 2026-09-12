import CommonCrypto
import CryptoKit
import Foundation
import Security

enum TransferKeyDeriver: Sendable {
    static let keyByteCount = 32
    static let saltByteCount = TransferFileFormat.saltByteCount
    /// PBKDF2-HMAC-SHA256 的工作因子。HKDF 没有这一项，不能拿来抗低熵口令。
    static let iterationCount = 600_000
    static let minimumIterationCount = 600_000
    /// 上限不是密码学要求，是拒绝服务防线：迭代数是文件里来的数字，
    /// 而且**必须在认证之前**读（要先派生密钥才能验 AAD）。不设上限的话，
    /// 一个头里写着 40 亿轮的文件能让导入空转一个多小时。
    /// 以后真要提高 `iterationCount`，这里要跟着抬，并且加一个新的格式版本。
    static let maximumIterationCount = 4_000_000

    static func makeSalt() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: saltByteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw TransferExportError.keyDerivationFailed
        }
        return Data(bytes)
    }

    static func derive(password: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        guard iterations >= 1, salt.count == saltByteCount else {
            throw TransferImportError.invalidFile
        }
        var derived = Data(count: keyByteCount)
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            password.withCString { pointer in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pointer,
                        password.utf8.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        keyByteCount
                    )
                }
            }
        }
        guard status == kCCSuccess else {
            throw TransferExportError.keyDerivationFailed
        }
        return SymmetricKey(data: derived)
    }
}
