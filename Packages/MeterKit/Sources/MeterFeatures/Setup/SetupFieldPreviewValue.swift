import Foundation
import MeterCore
import MeterPersistence

/// 验收和 Preview 用的占位值。必须过得了该字段自己的校验，不能再写死 Cloudflare 那两个键。
enum SetupFieldPreviewValue {
    static func make(for field: SetupField) -> String {
        let validation = field.validation
        var value = validation?.prefix ?? ""
        let allowed = validation?.allowedCharacters.map(Array.init)
        let target = targetLength(for: validation, prefixCount: value.count)

        while value.count < target {
            if let allowed, let scalar = allowed.first {
                value.append(scalar)
            } else {
                value.append("x")
            }
        }

        if let exact = validation?.exactLength {
            return String(value.prefix(exact))
        }
        return value
    }

    static func dictionary(for fields: [SetupField]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: fields.map { ($0.key, make(for: $0)) })
    }

    private static func targetLength(for validation: SetupFieldValidation?, prefixCount: Int) -> Int {
        if let exact = validation?.exactLength {
            return exact
        }
        if let minimum = validation?.minLength {
            return max(minimum, prefixCount)
        }
        return max(prefixCount + 8, 12)
    }
}
