#if os(Linux)
import CSecret
import Foundation

struct SecretServiceVault: CredentialVault {
    static var isAvailable: Bool { tollcat_secret_available() != 0 }

    func save(_ secret: String, reference: String) throws {
        let ok = secret.withCString { secretPointer in
            reference.withCString { referencePointer in
                tollcat_secret_store(referencePointer, secretPointer)
            }
        }
        guard ok != 0 else { throw CredentialVaultError.saveFailed }
    }

    func read(reference: String) throws -> String? {
        let pointer = reference.withCString { tollcat_secret_lookup($0) }
        guard let pointer else { return nil }
        defer { tollcat_secret_free(pointer) }
        return String(cString: pointer)
    }

    func delete(reference: String) throws {
        _ = reference.withCString { tollcat_secret_clear($0) }
    }
}
#endif
