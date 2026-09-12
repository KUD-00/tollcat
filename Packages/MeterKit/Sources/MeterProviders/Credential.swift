import Foundation
import MeterCore

/// 一次取数需要的字段集合。只在内存里传递，不负责存 Keychain。
///
/// 用字典而不是关联值枚举：各家字段组合不同，字典加 `CredentialField`
/// 取值就能覆盖，又不必每加一家就改枚举。密钥的打印 / 编码出口只有这一处。
public struct Credential: Sendable, Equatable, Hashable {
    public var providerID: ProviderID
    private var fields: [CredentialField: String]

    public init(providerID: ProviderID, fields: [CredentialField: String]) {
        self.providerID = providerID
        self.fields = fields
    }

    public func value(for field: CredentialField) -> String? {
        fields[field]
    }

    public var fieldKeys: [CredentialField] {
        CredentialField.allCases.filter { fields[$0] != nil }
    }
}

extension Credential: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        redactedDescription
    }

    public var debugDescription: String {
        redactedDescription
    }

    private var redactedDescription: String {
        let keys = fieldKeys.map(\.rawValue).joined(separator: ", ")
        if keys.isEmpty {
            return "Credential(\(providerID.rawValue))"
        }
        return "Credential(\(providerID.rawValue); \(keys))"
    }
}

extension Credential: CustomReflectable {
    /// 避免 `dump` / Mirror 把密钥打进日志。
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "providerID": providerID.rawValue,
                "fields": fieldKeys.map(\.rawValue),
            ],
            displayStyle: .struct
        )
    }
}

extension Credential: Codable {
    private enum CodingKeys: String, CodingKey {
        case providerID
        case fieldKeys
    }

    /// 只编字段名。值出了进程就不该再出现。
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(providerID, forKey: .providerID)
        try container.encode(fieldKeys, forKey: .fieldKeys)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        providerID = try container.decode(ProviderID.self, forKey: .providerID)
        fields = [:]
    }
}
