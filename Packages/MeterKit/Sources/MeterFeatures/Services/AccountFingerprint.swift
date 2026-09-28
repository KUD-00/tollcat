import CryptoKit
import Foundation
import MeterCore
import MeterProviders

/// 非密字段的远程身份指纹。密钥本身永不进哈希。
enum AccountFingerprint {
    static func hash(providerID: ProviderID, fields: [String: String]) -> String? {
        guard let canonical = canonicalString(fields: fields) else { return nil }
        var data = Data(providerID.rawValue.utf8)
        data.append(0x00)
        data.append(Data(canonical.utf8))
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// 给 VoiceOver 碰撞消歧 / 详情脚注用。密钥字段永不进 hint。
    static func identityHint(from fields: [String: String]) -> String? {
        let email = trimmed(fields[CredentialField.email.rawValue])
        if let email {
            let local = email.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
                .first
                .map(String.init) ?? email
            let value = local.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        let ordered: [CredentialField] = [
            .accountID, .accessKeyID, .clientID, .tenantID, .projectID, .keyID,
        ]
        for field in ordered {
            guard let raw = trimmed(fields[field.rawValue]) else { continue }
            let suffix = String(raw.suffix(4))
            if field == .accountID {
                return String(localized: L("Account ID · \(suffix)"))
            }
            return suffix
        }
        return nil
    }

    static func canonicalString(fields: [String: String]) -> String? {
        var pairs: [(name: String, value: String)] = []
        for field in CredentialField.allCases where field.contributesToRemoteIdentity {
            guard var value = trimmed(fields[field.rawValue]) else { continue }
            if field == .email {
                value = value.lowercased(with: Locale(identifier: "en_US_POSIX"))
            }
            pairs.append((name: field.rawValue, value: value))
        }
        guard !pairs.isEmpty else { return nil }
        // 行分隔符是 "\n"：值里夹着换行，{accountID:"y\nemail=x"} 就会和
        // {accountID:"y", email:"x"} 拼出同一串、同一个指纹，被当成同一个远程账号。
        // 已落盘的指纹要能继续比对，所以不含换行的输入保持原编码逐字节不变；
        // 只有含 CR/LF 的才改走长度前缀编码。
        if pairs.contains(where: { containsLineBreak($0.value) }) {
            return lengthPrefixedCanonical(pairs)
        }
        var rows = pairs.map { "\($0.name)=\($0.value)" }
        rows.sort()
        return rows.joined(separator: "\n")
    }

    /// 以 NUL 开头：旧编码第一个字符永远是字段名字母，两种编码不可能撞上。
    /// 每行 `名=字节数:值`，字段名来自固定枚举且不含 "="，按字节数截值，整串只有一种读法。
    private static func lengthPrefixedCanonical(_ pairs: [(name: String, value: String)]) -> String {
        let rows = pairs
            .sorted { $0.name < $1.name }
            .map { "\($0.name)=\($0.value.utf8.count):\($0.value)" }
        return "\u{0}v2\n" + rows.joined()
    }

    /// 按 unicode scalar 查：Swift 把 "\r\n" 当成一个 Character，`contains("\n")` 会漏掉它，
    /// 但哈希吃的是字节，里面照样有 0x0A。
    private static func containsLineBreak(_ value: String) -> Bool {
        value.unicodeScalars.contains { $0 == "\n" || $0 == "\r" }
    }

    /// 无非密字段时，在内存里比同厂商其它账号的密钥。比较结果不落盘。
    static func secretsCollide(_ lhs: [String: String], _ rhs: [String: String]) -> Bool {
        let secretKeys = CredentialField.allCases
            .filter { !$0.contributesToRemoteIdentity }
            .map(\.rawValue)
        var compared = false
        for key in secretKeys {
            let a = trimmed(lhs[key])
            let b = trimmed(rhs[key])
            guard let a, let b else { continue }
            compared = true
            if a != b { return false }
        }
        return compared
    }

    private static func trimmed(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
