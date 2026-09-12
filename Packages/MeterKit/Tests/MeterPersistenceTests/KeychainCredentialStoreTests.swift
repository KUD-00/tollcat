import Foundation
import Testing
@testable import MeterPersistence

struct KeychainCredentialStoreTests {
    private let store = KeychainCredentialStore(service: "com.zhechengqi.tollcat.credentials.tests")

    @Test("存")
    func save() throws {
        let reference = uniqueReference()
        defer { try? store.delete(reference: reference) }

        try store.save("cf-test-token", reference: reference)
        #expect(try store.read(reference: reference) == "cf-test-token")
    }

    @Test("读")
    func read() throws {
        let reference = uniqueReference()
        defer { try? store.delete(reference: reference) }

        try store.save("openai-admin-key", reference: reference)
        #expect(try store.read(reference: reference) == "openai-admin-key")
    }

    @Test("删")
    func delete() throws {
        let reference = uniqueReference()
        defer { try? store.delete(reference: reference) }

        try store.save("to-be-deleted", reference: reference)
        try store.delete(reference: reference)
        #expect(try store.read(reference: reference) == nil)
    }

    @Test("读不存在的 reference")
    func readMissingReference() throws {
        let reference = uniqueReference()
        defer { try? store.delete(reference: reference) }

        #expect(try store.read(reference: reference) == nil)
    }

    @Test("deleteAll 清掉该 service 下所有条目")
    func deleteAll() throws {
        let first = uniqueReference()
        let second = uniqueReference()
        defer {
            try? store.delete(reference: first)
            try? store.delete(reference: second)
        }

        try store.save("first", reference: first)
        try store.save("second", reference: second)
        try store.deleteAll()

        #expect(try store.read(reference: first) == nil)
        #expect(try store.read(reference: second) == nil)
    }

    private func uniqueReference() -> String {
        "tollcat.test.\(UUID().uuidString)"
    }
}
