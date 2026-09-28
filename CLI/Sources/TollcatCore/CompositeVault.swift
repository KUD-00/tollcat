struct CompositeVault: CredentialVault {
    var primary: any CredentialVault

    func save(_ secret: String, reference: String) throws {
        try primary.save(secret, reference: reference)
    }

    func read(reference: String) throws -> String? {
        try primary.read(reference: reference)
    }

    func delete(reference: String) throws {
        try primary.delete(reference: reference)
    }
}
