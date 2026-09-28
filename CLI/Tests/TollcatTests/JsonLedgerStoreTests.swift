import Foundation
import Testing
@testable import TollcatCore

struct JsonLedgerStoreTests {
    @Test func roundTripMembershipAccountAndSnapshot() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("tollcat-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: path) }
        let store = JsonLedgerStore(path: path)
        store.upsertMembership(LedgerMembership(providerId: "openai", sortIndex: 0))
        let account = LedgerAccount(
            accountId: UUID().uuidString,
            providerId: "openai",
            credentialReference: "acct.1",
            sortIndex: 0
        )
        store.upsertAccount(account)
        store.replaceAccountSnapshots(
            accountID: account.accountId,
            snapshot: LedgerSnapshot(
                providerId: "openai",
                accountId: account.accountId,
                kind: "usage",
                source: "api",
                currentSpendUsd: "7.62",
                balanceUsd: nil,
                committedMonthlyUsd: nil,
                chargeDayOfMonth: nil,
                freeQuotaUsedRatio: nil,
                dailyUsdJson: nil,
                convertedJson: nil,
                walletsJson: nil,
                periodStartMillis: 0,
                periodEndMillis: 0,
                fetchedAtMillis: 1_700_000_000_000
            )
        )
        #expect(store.memberships().count == 1)
        #expect(store.accounts(providerID: "openai").count == 1)
        #expect(store.snapshots().first?.currentSpendUsd == "7.62")

        let reload = JsonLedgerStore(path: path)
        #expect(reload.memberships().first?.providerId == "openai")
        #expect(reload.snapshots().first?.currentSpendUsd == "7.62")
    }

    @Test func twoProcessesDoNotDropEachOthersRows() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("tollcat-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: path) }
        // 两个进程各自在对方写之前读进账本。
        let first = JsonLedgerStore(path: path)
        let second = JsonLedgerStore(path: path)
        first.upsertMembership(LedgerMembership(providerId: "openai", sortIndex: 0))
        second.upsertMembership(LedgerMembership(providerId: "neon", sortIndex: 1))
        let reload = JsonLedgerStore(path: path)
        #expect(Set(reload.memberships().map(\.providerId)) == ["openai", "neon"])
        #expect(Set(second.memberships().map(\.providerId)) == ["openai", "neon"])
    }

    @Test func ledgerIsOwnerOnly() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("tollcat-test-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: path)
            try? FileManager.default.removeItem(at: path.appendingPathExtension("lock"))
        }
        JsonLedgerStore(path: path).upsertMembership(LedgerMembership(providerId: "openai", sortIndex: 0))
        for file in [path, path.appendingPathExtension("lock")] {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        }
    }

    @Test func sharedFixture() throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("shared/fixtures/ledger-v4.json")
        #expect(FileManager.default.isReadableFile(atPath: fixture.path))
        let copy = FileManager.default.temporaryDirectory
            .appendingPathComponent("tollcat-shared-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: fixture, to: copy)
        defer { try? FileManager.default.removeItem(at: copy) }
        let store = JsonLedgerStore(path: copy)
        #expect(store.memberships().first?.providerId == "openai")
        #expect(store.snapshots().first?.currentSpendUsd == "7.62")
        #expect(store.accounts().first?.credentialReference.contains("acct.") == true)
    }
}
