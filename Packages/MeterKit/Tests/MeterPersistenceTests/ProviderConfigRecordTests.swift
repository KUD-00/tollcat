import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct ProviderConfigRecordTests {
    @Test("ProviderConfigRecord 没有任何能存密钥的字段")
    func providerConfigRecordHasNoSecretFields() {
        let names = storedAttributeNames(of: ProviderConfigRecord.self)
        #expect(!names.isEmpty)

        let allowed: Set<String> = [
            "accountIDRaw",
            "providerIDRaw",
            "nickname",
            "identityHint",
            "remoteIdentityFingerprint",
            "isEnabled",
            "archivedAt",
            // 结束那一天的日历分量。存瞬间的话，「本地 8/31 23:30」在另一本
            // 日历上是 9/1，那一家的最后一个月会整月挪位。
            "archivedDay",
            "sortIndex",
            "lastSuccessfulRefreshAt",
            "credentialReference",
            "includeInGlobalRefresh",
            "usesInbox",
            "inboxIngestKeyID",
        ]
        #expect(names.isSubset(of: allowed))
        #expect(allowed.isSubset(of: names))

        let secretTokens = [
            "secret",
            "password",
            "token",
            "apikey",
            "api_key",
            "credentialvalue",
            "privatekey",
        ]
        for name in names {
            let folded = name.lowercased().replacingOccurrences(of: "_", with: "")
            if name == "credentialReference" {
                continue
            }
            for token in secretTokens {
                #expect(!folded.contains(token), "\(name) looks like it can store a secret")
            }
        }
    }

    @Test("删除接入时连带删掉 Keychain 引用对应的密钥")
    func deletingProviderRemovesCredential() throws {
        let credentials = InMemoryCredentialStore()
        let reference = "provider.cloudflare"
        try credentials.save("cf-secret", reference: reference)

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let record = ProviderConfigRecord(
            accountID: AccountID.fixture(for: .cloudflare),
            providerID: .cloudflare,
            isEnabled: true,
            sortIndex: 0,
            credentialReference: reference
        )
        context.insert(record)
        try context.save()

        try record.deleteTogetherWithCredentials(in: context, credentials: credentials)
        try context.save()

        #expect(try credentials.read(reference: reference) == nil)
        #expect(try context.fetch(FetchDescriptor<ProviderConfigRecord>()).isEmpty)
    }

    private func storedAttributeNames(of model: any PersistentModel.Type) -> Set<String> {
        let entity = PersistenceContainer.schema.entities.first {
            $0.name == String(describing: model)
        }
        guard let entity else { return [] }
        return Set(entity.attributesByName.keys)
    }
}
