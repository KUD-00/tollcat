import CryptoKit
import Foundation

enum TransferCryptor: Sendable {
    static func seal(
        plaintext: Data,
        password: String,
        now: Date,
        lifetime: TimeInterval
    ) throws -> (fileBytes: Data, notAfter: Date) {
        let salt = try TransferKeyDeriver.makeSalt()
        let key = try TransferKeyDeriver.derive(
            password: password,
            salt: salt,
            iterations: TransferKeyDeriver.iterationCount
        )
        let nonce = AES.GCM.Nonce()
        let notAfterSeconds = UInt64(
            max(0, now.addingTimeInterval(lifetime).timeIntervalSince1970.rounded(.down))
        )
        let nonceData = Data(nonce)
        guard salt.count == TransferFileFormat.saltByteCount,
              nonceData.count == TransferFileFormat.nonceByteCount else {
            throw TransferExportError.sealingFailed
        }
        let header = TransferFileHeader(
            version: TransferFileFormat.version,
            salt: salt,
            iterations: UInt32(TransferKeyDeriver.iterationCount),
            nonce: nonceData,
            notAfter: notAfterSeconds
        )
        let headerBytes = header.encoded()
        let sealed: AES.GCM.SealedBox
        do {
            sealed = try AES.GCM.seal(
                plaintext,
                using: key,
                nonce: nonce,
                authenticating: headerBytes
            )
        } catch {
            throw TransferExportError.sealingFailed
        }
        var file = headerBytes
        file.append(sealed.ciphertext)
        file.append(sealed.tag)
        return (file, Date(timeIntervalSince1970: TimeInterval(notAfterSeconds)))
    }

    static func open(fileBytes: Data, password: String, now: Date) throws -> Data {
        let parts = try TransferEnvelope.split(fileBytes)
        guard parts.header.version == TransferFileFormat.version else {
            throw TransferImportError.unsupportedVersion
        }
        // 迭代数必须在派生**之前**卡住区间。
        //
        // AAD 挡不住这个：要验 AAD 就得先有密钥，要有密钥就得先照着这个数字跑
        // PBKDF2。也就是说这个数字在被认证之前就已经决定了要烧多少 CPU。
        // 下限防的是有人把它调小来削弱密钥，上限防的是有人把它调大把 App 挂死。
        guard parts.header.iterations >= UInt32(TransferKeyDeriver.minimumIterationCount),
              parts.header.iterations <= UInt32(TransferKeyDeriver.maximumIterationCount) else {
            throw TransferImportError.weakKeyDerivation
        }
        let key = try TransferKeyDeriver.derive(
            password: password,
            salt: parts.header.salt,
            iterations: Int(parts.header.iterations)
        )
        let nonce: AES.GCM.Nonce
        let box: AES.GCM.SealedBox
        do {
            nonce = try AES.GCM.Nonce(data: parts.header.nonce)
            box = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: parts.ciphertext,
                tag: parts.tag
            )
        } catch {
            throw TransferImportError.invalidFile
        }
        let plaintext: Data
        do {
            // 明文头整段做 AAD。否则攻击者可以把迭代数改成 1 再喂给导入方。
            plaintext = try AES.GCM.open(
                box,
                using: key,
                authenticating: parts.header.encoded()
            )
        } catch {
            throw TransferImportError.authenticationFailed
        }
        // 认证通过之后才看过期。过期字段被 AAD 罩住，改它会先认证失败。
        // 过期不是密码学保护：拿到文件的人离线穷举根本不看这个字段。
        let deadline = Date(timeIntervalSince1970: TimeInterval(parts.header.notAfter))
        if now >= deadline {
            throw TransferImportError.expired
        }
        return plaintext
    }
}
