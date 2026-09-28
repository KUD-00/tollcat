#if os(macOS)
import Foundation
import Security

/// CLI 不是带 entitlement 的 App 包，不能走 Data Protection Keychain。
struct KeychainVault: CredentialVault {
    var service: String

    init(service: String = "app.tollcat.cli") {
        self.service = service
    }

    /// 不原地 SecItemUpdate：同一用户下的别的进程可以抢先埋一条同 service/account 的条目，
    /// 带宽松 ACL 或可同步属性；update 只换数据，那些属性会原样留下，凭据等于写进了别人的条目。
    /// 所以先把同名条目（含可同步的）全删掉，删不掉就不写，再按本类的属性新建。
    func save(_ secret: String, reference: String) throws {
        let data = Data(secret.utf8)
        let query = baseQuery(reference: reference)
        var existing = query
        existing[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        let removal = SecItemDelete(existing as CFDictionary)
        guard removal == errSecSuccess || removal == errSecItemNotFound else {
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
        var query = baseQuery(reference: reference)
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialVaultError.deleteFailed
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
