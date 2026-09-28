import Foundation

final class MemoryVault: CredentialVault, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String] = [:]

    func save(_ secret: String, reference: String) throws {
        lock.lock()
        storage[reference] = secret
        lock.unlock()
    }

    func read(reference: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[reference]
    }

    func delete(reference: String) throws {
        lock.lock()
        storage.removeValue(forKey: reference)
        lock.unlock()
    }
}
