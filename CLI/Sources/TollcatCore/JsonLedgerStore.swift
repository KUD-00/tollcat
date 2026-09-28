import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

final class JsonLedgerStore: @unchecked Sendable {
    private let path: URL
    private let lock = NSLock()
    private var document: LedgerDocument

    init(path: URL) {
        self.path = path
        self.document = Self.load(path)
    }

    func snapshots() -> [LedgerSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        return document.snapshots.sorted { $0.fetchedAtMillis < $1.fetchedAtMillis }
    }

    func memberships() -> [LedgerMembership] {
        lock.lock()
        defer { lock.unlock() }
        return document.memberships.sorted { $0.sortIndex < $1.sortIndex }
    }

    func accounts() -> [LedgerAccount] {
        lock.lock()
        defer { lock.unlock() }
        return document.accounts.sorted { $0.sortIndex < $1.sortIndex }
    }

    func accounts(providerID: String) -> [LedgerAccount] {
        accounts().filter { $0.providerId == providerID }
    }

    func subscriptions() -> [LedgerSubscription] {
        lock.lock()
        defer { lock.unlock() }
        return document.subscriptions.sorted { $0.name < $1.name }
    }

    func upsertMembership(_ row: LedgerMembership) {
        mutate { document in
            document.memberships.removeAll { $0.providerId == row.providerId }
            document.memberships.append(row)
        }
    }

    func upsertAccount(_ row: LedgerAccount) {
        mutate { document in
            document.accounts.removeAll { $0.accountId == row.accountId }
            document.accounts.append(row)
        }
    }

    func replaceAccountSnapshots(accountID: String, snapshot: LedgerSnapshot) {
        mutate { document in
            document.snapshots.removeAll { $0.accountId == accountID }
            document.snapshots.append(snapshot)
        }
    }

    func deleteMembership(providerID: String) {
        mutate { document in
            let accountIDs = Set(document.accounts.filter { $0.providerId == providerID }.map(\.accountId))
            document.snapshots.removeAll { accountIDs.contains($0.accountId) }
            document.accounts.removeAll { $0.providerId == providerID }
            document.subscriptions.removeAll { $0.providerId == providerID }
            document.memberships.removeAll { $0.providerId == providerID }
        }
    }

    private func mutate(_ body: (inout LedgerDocument) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        withFileLock {
            body(&document)
            persistLocked()
        }
    }

    private func persistLocked() {
        let directory = path.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(document) else { return }
        let temporary = path.appendingPathExtension("tmp")
        try? data.write(to: temporary, options: .atomic)
        _ = try? FileManager.default.replaceItemAt(path, withItemAt: temporary)
        if !FileManager.default.fileExists(atPath: path.path) {
            try? data.write(to: path, options: .atomic)
        }
    }

    private func withFileLock(_ body: () -> Void) {
        let lockURL = path.appendingPathExtension("lock")
        try? FileManager.default.createDirectory(
            at: lockURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let fd = open(lockURL.path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else {
            body()
            return
        }
        _ = flock(fd, LOCK_EX)
        defer {
            _ = flock(fd, LOCK_UN)
            close(fd)
        }
        body()
    }

    private static func load(_ path: URL) -> LedgerDocument {
        guard let data = try? Data(contentsOf: path) else {
            return .empty()
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode(LedgerDocument.self, from: data)) ?? .empty()
    }
}
