import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct ProviderConfigStoreTests {
    @Test("同一厂商两行不同账号可以共存")
    func twoAccountsSameVendorInsert() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let first = AccountID.fixture(1)
        let second = AccountID.fixture(2)
        _ = try insert(accountID: first, providerID: .cloudflare, placement: .afterSiblings, in: context)
        _ = try insert(accountID: second, providerID: .cloudflare, placement: .afterSiblings, in: context)
        try context.save()
        let records = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        #expect(records.count == 2)
        #expect(Set(records.map(\.providerIDRaw)) == ["cloudflare"])
        #expect(try Set(records.map { try $0.domainAccountID() }) == [first, second])
    }

    @Test("无 sibling 时接到全局 max+1 且不 shift")
    func afterSiblingsWithoutSiblingsAppends() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        _ = try insert(
            accountID: AccountID.fixture(1),
            providerID: .aws,
            placement: .exact(4),
            in: context
        )
        let inserted = try insert(
            accountID: AccountID.fixture(2),
            providerID: .cloudflare,
            placement: .afterSiblings,
            in: context
        )
        try context.save()
        #expect(inserted.sortIndex == 5)
        let aws = try context.fetch(FetchDescriptor<ProviderConfigRecord>()).first { $0.providerID == .aws }
        #expect(aws?.sortIndex == 4)
    }

    @Test("有 sibling 时插在该厂商 max+1 并 shift 其后的行")
    func afterSiblingsShiftsLaterRows() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        _ = try insert(accountID: AccountID.fixture(1), providerID: .cloudflare, placement: .exact(0), in: context)
        _ = try insert(accountID: AccountID.fixture(2), providerID: .openai, placement: .exact(1), in: context)
        let secondCF = try insert(
            accountID: AccountID.fixture(3),
            providerID: .cloudflare,
            placement: .afterSiblings,
            in: context
        )
        try context.save()
        #expect(secondCF.sortIndex == 1)
        let openai = try context.fetch(FetchDescriptor<ProviderConfigRecord>()).first { $0.providerID == .openai }
        #expect(openai?.sortIndex == 2)
    }

    private func insert(
        accountID: AccountID,
        providerID: ProviderID,
        placement: AccountInsertPlacement,
        in context: ModelContext
    ) throws -> ProviderConfigRecord {
        try ProviderConfigStore.insert(
            accountID: accountID,
            providerID: providerID,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: "credential.\(accountID.rawValue.uuidString)",
            includeInGlobalRefresh: true,
            usesInbox: nil,
            inboxIngestKeyID: nil,
            lastSuccessfulRefreshAt: nil,
            placement: placement,
            in: context
        )
    }
}
