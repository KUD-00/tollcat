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
        var rows: [String] = []
        for field in CredentialField.allCases where field.contributesToRemoteIdentity {
            guard var value = trimmed(fields[field.rawValue]) else { continue }
            if field == .email {
                value = value.lowercased(with: Locale(identifier: "en_US_POSIX"))
            }
            rows.append("\(field.rawValue)=\(value)")
        }
        guard !rows.isEmpty else { return nil }
        rows.sort()
        return rows.joined(separator: "\n")
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
