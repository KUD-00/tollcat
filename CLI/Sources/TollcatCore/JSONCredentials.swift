import Foundation

enum JSONCredentials {
    static func encode(_ fields: [String: String]) -> String {
        let object = fields as [String: Any]
        return (JSONSerialization.isValidJSONObject(object)
            ? (try? JSONSerialization.data(withJSONObject: object)).flatMap { String(data: $0, encoding: .utf8) }
            : nil) ?? "{}"
    }

    static func decode(_ raw: String?) -> [String: String] {
        guard let raw, let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        var result: [String: String] = [:]
        for (key, value) in object {
            if let string = value as? String, !string.isEmpty {
                result[key] = string
            }
        }
        return result
    }
}
