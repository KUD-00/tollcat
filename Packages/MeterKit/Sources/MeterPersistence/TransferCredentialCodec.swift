import Foundation

/// Keychain 一条引用要装下多家字段（token + account id）。内容是 JSON 对象。
/// 编解码只有这一份；Features 侧的 `StoredCredentialFields` 只做
/// CredentialField→Credential 的映射，encode/decode 转调这里。
public enum CredentialFieldsCodec: Sendable {
    public enum CodecError: Error, Equatable, Sendable {
        case encodingFailed
        case decodingFailed
    }

    public static func decode(_ raw: String) throws -> [String: String] {
        guard let data = raw.data(using: .utf8),
              let fields = try? JSONDecoder().decode([String: String].self, from: data) else {
            throw CodecError.decodingFailed
        }
        return fields
    }

    public static func encode(_ fields: [String: String]) throws -> String {
        let data = try JSONEncoder().encode(fields)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CodecError.encodingFailed
        }
        return string
    }
}
