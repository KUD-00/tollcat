protocol CredentialVault: Sendable {
    func save(_ secret: String, reference: String) throws
    func read(reference: String) throws -> String?
    func delete(reference: String) throws
}

enum CredentialVaultError: Error, Equatable {
    case saveFailed
    case readFailed
    case deleteFailed
    case unavailable
}
