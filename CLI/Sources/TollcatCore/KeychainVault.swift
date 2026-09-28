#if os(macOS)
import Foundation
import Security

/// CLI 不是带 entitlement 的 App 包，不能走 Data Protection Keychain。
struct KeychainVault: CredentialVault {
    var service: String

    init(service: String = "app.tollcat.cli") {
        self.service = service
    }

    func save(_ secret: String, reference: String) throws {
        let data = Data(secret.utf8)
        let query = baseQuery(reference: reference)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let update = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if update == errSecSuccess { return }
        if update != errSecItemNotFound {
            throw CredentialVaultError.saveFailed
        }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        add[kSecAttrSynchronizable as String] = kCFBooleanFalse as Any
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CredentialVaultError.saveFailed
        }
    }

    func read(reference: String) throws -> String? {
        var query = baseQuery(reference: reference)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw CredentialVaultError.readFailed
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(reference: String) throws {
        let status = SecItemDelete(baseQuery(reference: reference) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialVaultError.readFailed
        }
    }

    private func baseQuery(reference: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference,
        ]
    }
}
#endif
