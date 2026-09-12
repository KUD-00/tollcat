import Foundation
import SwiftData
import Testing
import MeterCore
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

@MainActor
struct InboxLaneIsolationTests {
    @Test("走信箱的家不进 provider 泳道")
    func inboxProvidersAreExcludedFromBillingJobs() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let credentials = InMemoryCredentialStore()
        let context = ModelContext(container)
        let render = AccountID.fixture(for: .render)
        let cloudflare = AccountID.fixture(for: .cloudflare)

        _ = try ProviderConfigStore.insert(
            accountID: render,
            providerID: .render,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: "render-ref",
            includeInGlobalRefresh: nil,
            usesInbox: true,
            inboxIngestKeyID: "key_render",
            lastSuccessfulRefreshAt: nil,
            placement: .exact(0),
            in: context
        )
        _ = try ProviderConfigStore.insert(
            accountID: cloudflare,
            providerID: .cloudflare,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            isEnabled: true,
            credentialReference: "cf-ref",
            includeInGlobalRefresh: nil,
            usesInbox: false,
            inboxIngestKeyID: nil,
            lastSuccessfulRefreshAt: nil,
            placement: .exact(1),
            in: context
        )
        try context.save()

        let providers = ProviderAssembly.make(
            now: { Date() },
            calendar: .current,
            httpClient: StubHTTPClient(responses: [:])
        )
        let jobs = BillingRefreshJobs.make(
            ids: [render, cloudflare],
            container: container,
            credentials: credentials,
            providers: providers
        )

        #expect(jobs.map(\.id) == [cloudflare])
        #expect(!jobs.contains { $0.id == render })
    }

    @Test("目录里开了信箱的家和实现里的一致")
    func catalogAndLaneAgreeOnWhoUsesInbox() {
        let opened = ProviderCatalog.all.filter(\.supportsInboxIngest).map(\.id)
        #expect(Set(opened) == Set([
            .render, .expo, .clerk, .fly, .gitlab,
            .supabase, .linear, .slack, .notion, .gcp, .pulumi, .figma,
        ]))
        for id in opened {
            #expect(!ProviderAssembly.liveRESTProviderIDs.contains(id))
        }
    }
}
