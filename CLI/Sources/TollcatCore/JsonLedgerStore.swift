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

    /// 改动必须落在拿到文件锁之后重读的那份上：init 时读进来的快照可能早被另一个
    /// tollcat 进程改过，拿它写回会把对方那行盖掉。锁拿不到就不写——没锁的并发写者
    /// 同样会互相覆盖账本。
    private func mutate(_ body: (inout LedgerDocument) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        withFileLock {
            var fresh = Self.load(path)
            body(&fresh)
            persistLocked(fresh)
            document = fresh
        }
    }

    /// 账本里有账户、订阅和金额，只给本人读写：umask 022 下默认会落成 0644。
    private func persistLocked(_ document: LedgerDocument) {
        let fileManager = FileManager.default
        let directory = path.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(document) else { return }
        let temporary = path.appendingPathExtension("tmp")
        try? data.write(to: temporary, options: .atomic)
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporary.path)
        _ = try? fileManager.replaceItemAt(path, withItemAt: temporary)
        if !fileManager.fileExists(atPath: path.path) {
            try? data.write(to: path, options: .atomic)
        }
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
    }

    private func withFileLock(_ body: () -> Void) {
        let lockURL = path.appendingPathExtension("lock")
        try? FileManager.default.createDirectory(
            at: lockURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let fd = open(lockURL.path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { return }
        defer { close(fd) }
        _ = fchmod(fd, 0o600)
        guard flock(fd, LOCK_EX) == 0 else { return }
        defer { _ = flock(fd, LOCK_UN) }
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
