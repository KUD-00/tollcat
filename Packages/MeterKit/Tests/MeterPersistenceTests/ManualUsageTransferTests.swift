import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct ManualUsageTransferTests {
    @Test("当月手填进出迁移包，并写成快照")
    func typedUsageSurvivesTransfer() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sourceCredentials = InMemoryCredentialStore()
        let source = try PersistenceContainer.makeContainer(inMemory: true)
        let sourceContext = ModelContext(source)
        let account = AccountID.fixture(for: .fly)
        try sourceCredentials.save(
            CredentialFieldsCodec.encode([:]),
            reference: "credential.fly"
        )
        sourceContext.insert(
            ProviderConfigRecord(
                accountID: account,
                providerID: .fly,
                isEnabled: true,
                sortIndex: 0,
                credentialReference: "credential.fly",
                includeInGlobalRefresh: false,
                usesInbox: false
            )
        )
        try ProviderMembershipStore.ensure(.fly, in: sourceContext)
        _ = try ManualUsageStore.upsert(
            accountID: account,
            providerID: .fly,
            periodYear: 2026,
            periodMonth: 8,
            amount: Money(usd: Decimal(string: "12.34")!),
            enteredAt: now,
            kind: .usage,
            in: sourceContext
        )
        try sourceContext.save()

        let exported = try DeviceTransfer.makeExport(
            container: source,
            credentials: sourceCredentials,
            now: now,
            calendar: calendar,
            code: .generate()
        )
        let destination = try PersistenceContainer.makeContainer(inMemory: true)
        let destinationCredentials = InMemoryCredentialStore()
        try DeviceTransfer.applyImport(
            fileBytes: exported.fileBytes,
            code: exported.code,
            container: destination,
            credentials: destinationCredentials,
            now: now.addingTimeInterval(60),
            calendar: calendar
        )

        let dest = ModelContext(destination)
        let usages = try dest.fetch(FetchDescriptor<ManualUsageRecord>())
        #expect(usages.count == 1)
        #expect(usages[0].amount == Money(usd: Decimal(string: "12.34")!))
        #expect(usages[0].periodYear == 2026)
        #expect(usages[0].periodMonth == 8)
        let snapshots = try dest.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(snapshots.count == 1)
        let snapshot = try snapshots[0].toDomain(calendar: calendar)
        #expect(snapshot.source == .manual)
        #expect(snapshot.currentSpendUSD == Money(usd: Decimal(string: "12.34")!))
        #expect(snapshot.accountID == account)
    }

    @Test("两个月的手填都进迁移包")
    func twoMonthsSurviveTransfer() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let sourceCredentials = InMemoryCredentialStore()
        let source = try PersistenceContainer.makeContainer(inMemory: true)
        let sourceContext = ModelContext(source)
        let account = AccountID.fixture(for: .fly)
        try sourceCredentials.save(
            CredentialFieldsCodec.encode([:]),
            reference: "credential.fly"
        )
        sourceContext.insert(
            ProviderConfigRecord(
                accountID: account,
                providerID: .fly,
                isEnabled: true,
                sortIndex: 0,
                credentialReference: "credential.fly",
                includeInGlobalRefresh: false,
                usesInbox: false
            )
        )
        try ProviderMembershipStore.ensure(.fly, in: sourceContext)
        _ = try ManualUsageStore.upsert(
            accountID: account,
            providerID: .fly,
            periodYear: 2026,
            periodMonth: 7,
            amount: Money(usd: 40),
            enteredAt: now.addingTimeInterval(-86400),
            kind: .usage,
            in: sourceContext
        )
        _ = try ManualUsageStore.upsert(
            accountID: account,
            providerID: .fly,
            periodYear: 2026,
            periodMonth: 8,
            amount: Money(usd: Decimal(string: "12.34")!),
            enteredAt: now,
            kind: .usage,
            in: sourceContext
        )
        try sourceContext.save()

        let exported = try DeviceTransfer.makeExport(
            container: source,
            credentials: sourceCredentials,
            now: now,
            calendar: calendar,
            code: .generate()
        )
        let destination = try PersistenceContainer.makeContainer(inMemory: true)
        let destinationCredentials = InMemoryCredentialStore()
        try DeviceTransfer.applyImport(
            fileBytes: exported.fileBytes,
            code: exported.code,
            container: destination,
            credentials: destinationCredentials,
            now: now.addingTimeInterval(60),
            calendar: calendar
        )

        let dest = ModelContext(destination)
        let usages = try dest.fetch(FetchDescriptor<ManualUsageRecord>())
        #expect(usages.count == 2)
        let months = Set(usages.map(\.periodMonth))
        #expect(months == [7, 8])
        let snapshots = try dest.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(snapshots.count == 2)
    }
}
