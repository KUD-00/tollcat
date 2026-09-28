struct NullVault: CredentialVault {
    func save(_ secret: String, reference: String) throws {
        _ = secret
        _ = reference
        throw CredentialVaultError.unavailable
    }

    func read(reference: String) throws -> String? {
        _ = reference
        return nil
    }

    func delete(reference: String) throws {
        _ = reference
    }
}
