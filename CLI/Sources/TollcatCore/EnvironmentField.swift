import Foundation

enum EnvironmentField {
    static func variableName(providerID: String, field: String) -> String {
        let provider = providerID.uppercased().replacingOccurrences(of: "-", with: "_")
        let fieldPart = field.uppercased()
        return "TOLLCAT_\(provider)_\(fieldPart)"
    }

    static func fields(
        providerID: String,
        keys: [String],
        environment: [String: String]
    ) -> [String: String] {
        var result: [String: String] = [:]
        for key in keys {
            let name = variableName(providerID: providerID, field: key)
            if let value = environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !value.isEmpty
            {
                result[key] = value
            }
        }
        return result
    }
}
