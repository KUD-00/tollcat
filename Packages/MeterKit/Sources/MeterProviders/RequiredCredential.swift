import Foundation
import MeterCore

enum RequiredCredential: Sendable {
    static func value(
        _ field: CredentialField,
        in credential: Credential,
        providerID: ProviderID
    ) throws -> String {
        let raw = credential.value(for: field)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else {
            throw ProviderError.missingCredential(providerID: providerID)
        }
        return raw
    }
}
