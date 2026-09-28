enum VaultFactory {
    static func make() -> any CredentialVault {
        #if os(macOS)
        return KeychainVault()
        #elseif os(Linux)
        if SecretServiceVault.isAvailable {
            return SecretServiceVault()
        }
        return NullVault()
        #else
        return NullVault()
        #endif
    }
}
