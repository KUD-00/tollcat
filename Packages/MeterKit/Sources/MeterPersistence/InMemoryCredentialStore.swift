import Foundation
import os

/// 测试和 Preview 用。生产路径必须走 Keychain。
public final class InMemoryCredentialStore: CredentialStore, Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [String: String]())

    public init() {}

    public func save(_ secret: String, reference: String) throws {
        storage.withLock { $0[reference] = secret }
    }

    public func read(reference: String) throws -> String? {
        storage.withLock { $0[reference] }
    }

    public func storedReferences() -> [String] {
        storage.withLock { Array($0.keys) }
    }

    public func delete(reference: String) throws {
        storage.withLock { _ = $0.removeValue(forKey: reference) }
    }

    public func deleteAll() throws {
        storage.withLock { $0.removeAll() }
    }
}
