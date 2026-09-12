import Foundation
import MeterCore
import MeterPersistence
import MeterProviders

/// Keychain 原始字符串 → `Credential` 的映射。编解码只有
/// `CredentialFieldsCodec`（MeterPersistence）一份，这里只转调。
enum StoredCredentialFields {
    static func encode(_ fields: [String: String]) throws -> String {
        try CredentialFieldsCodec.encode(fields)
    }

    static func decode(_ raw: String) throws -> [String: String] {
        try CredentialFieldsCodec.decode(raw)
    }

    static func credential(providerID: ProviderID, raw: String) throws -> Credential {
        let decoded = try decode(raw)
        var fields: [CredentialField: String] = [:]
        for (key, value) in decoded {
            if let field = CredentialField(rawValue: key) {
                fields[field] = value
            }
        }
        return Credential(providerID: providerID, fields: fields)
    }
}
