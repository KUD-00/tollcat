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
