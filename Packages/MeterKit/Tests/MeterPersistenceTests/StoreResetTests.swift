import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct StoreResetTests {
    @Test("清除全部数据会删掉 Snapshot、订阅、接入配置和 Keychain 条目")
    func clearAllRemovesRecordsAndCredentials() throws {
        let credentials = InMemoryCredentialStore()
        let firstReference = "credential.cloudflare"
        let secondReference = "demo.credential.openai"
        try credentials.save("cf-secret", reference: firstReference)
        try credentials.save("oa-secret", reference: secondReference)

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let fetchedAt = Date(timeIntervalSince1970: 1_787_000_000)
        context.insert(
            try SnapshotRecord(
                domain: Snapshot(
                    providerID: .cloudflare,
                    accountID: AccountID.fixture(for: .cloudflare),
                    kind: .usage,
                    fetchedAt: fetchedAt,
                    periodStart: fetchedAt,
                    periodEnd: fetchedAt,
                    currentSpendUSD: Money(roundedUSD: 11.05)
                ),
                calendar: utcCalendar
            )
        )
        context.insert(
            SubscriptionRecord(
                domain: MonthlySubscription(
                    name: "ChatGPT Plus",
                    amount: Money(usd: 20),
                    period: .monthly,
                    anchorDate: fetchedAt,
                    providerID: .openai
                ),
                calendar: utcCalendar
            )
        )
        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .cloudflare),
                providerID: .cloudflare,
                isEnabled: true,
                sortIndex: 0,
                lastSuccessfulRefreshAt: fetchedAt,
                credentialReference: firstReference
            )
        )
        context.insert(
            ProviderConfigRecord(
                accountID: AccountID.fixture(for: .openai),
                providerID: .openai,
                isEnabled: true,
                sortIndex: 1,
                credentialReference: secondReference
            )
        )
        try AppPreferencesRecord.save(
            AppPreferences(isDemoModeEnabled: true),
            to: context
        )
        _ = try ProviderMembershipStore.ensure(.cloudflare, in: context)
        _ = try ManualUsageStore.upsert(
            accountID: AccountID.fixture(for: .fly),
            providerID: .fly,
            periodYear: 2026,
            periodMonth: 8,
            amount: Money(usd: 4),
            enteredAt: fetchedAt,
            kind: .usage,
            in: context
        )
        try context.save()

        try StoreReset.clearAll(container: container, credentials: credentials)

        let fresh = ModelContext(container)
        #expect(try fresh.fetch(FetchDescriptor<SnapshotRecord>()).isEmpty)
        #expect(try fresh.fetch(FetchDescriptor<SubscriptionRecord>()).isEmpty)
        #expect(try fresh.fetch(FetchDescriptor<ManualUsageRecord>()).isEmpty)
        #expect(try fresh.fetch(FetchDescriptor<ProviderConfigRecord>()).isEmpty)
        #expect(try fresh.fetch(FetchDescriptor<ProviderMembershipRecord>()).isEmpty)
        #expect(try fresh.fetch(FetchDescriptor<AppPreferencesRecord>()).isEmpty)
        #expect(try credentials.read(reference: firstReference) == nil)
        #expect(try credentials.read(reference: secondReference) == nil)
        #expect(credentials.storedReferences().isEmpty)
    }

    @Test("清除名单必须盖住整个 schema：新模型漏归类在这里现形")
    func purgeListsCoverWholeSchema() {
        #expect(
            StoreReset.unclassifiedModelNames.isEmpty,
            Comment(rawValue: "未归类模型：\(StoreReset.unclassifiedModelNames.sorted().joined(separator: ", "))")
        )
    }

    @Test("清除账单数据不会删打赏记录")
    func clearAllLeavesTipRecords() throws {
        let credentials = InMemoryCredentialStore()
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try TipRecord.upsert(
            transactionID: "keep-me",
            productID: "com.zhechengqi.tollcat.tip.small",
            displayPrice: "6.00",
            purchasedAt: Date(timeIntervalSince1970: 1_787_000_000),
            jws: "jws",
            appVersion: "0.1.0",
            in: context
        )

        try StoreReset.clearAll(container: container, credentials: credentials)

        let remaining = try TipRecord.all(from: ModelContext(container))
        #expect(remaining.count == 1)
        #expect(remaining[0].transactionID == "keep-me")
    }

    @Test("Keychain deleteAll 清掉同一 service 下的全部条目")
    func keychainDeleteAllRemovesEveryItem() throws {
        let store = KeychainCredentialStore(service: "com.zhechengqi.tollcat.credentials.reset-tests")
        let first = "meter.reset.\(UUID().uuidString)"
        let second = "meter.reset.\(UUID().uuidString)"
        defer {
            try? store.delete(reference: first)
            try? store.delete(reference: second)
            try? store.deleteAll()
        }

        try store.save("one", reference: first)
        try store.save("two", reference: second)
        try store.deleteAll()

        #expect(try store.read(reference: first) == nil)
        #expect(try store.read(reference: second) == nil)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
