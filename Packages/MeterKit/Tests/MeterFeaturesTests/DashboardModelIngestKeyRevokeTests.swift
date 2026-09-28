import Foundation
import os
import SwiftData
import Testing
import MeterCore
import MeterInbox
import MeterPersistence
import MeterProviders
@testable import MeterFeatures

/// 投递 key 的吊销是断开的一部分：吊销不掉，本地这份记录（key 的最后一份 id）就不能丢。
@MainActor
struct DashboardModelIngestKeyRevokeTests {
    @Test("吊销失败时删用量身份整个抛出，账号和 key id 原样留着")
    func removeConnectionKeepsRecordWhenRevokeFails() async throws {
        let transport = ScriptedInboxTransport()
        transport.setRevokeStatus(503)
        let dashboard = try Self.makeDashboard(transport: transport)
        let accountID = try Self.seedInboxAccount(on: dashboard, keyID: "key_old")

        await #expect(throws: InboxError.self) {
            try await dashboard.removeConnection(accountID: accountID)
        }
        let state = try #require(dashboard.connectionStates().first { $0.accountID == accountID })
        #expect(state.isLive)
        #expect(state.inboxIngestKeyID == "key_old")
    }

    @Test("服务端说这把已经不在了（404）按吊销成功算，归档照常")
    func removeConnectionTreatsNotFoundAsRevoked() async throws {
        let transport = ScriptedInboxTransport()
        transport.setRevokeStatus(404)
        let dashboard = try Self.makeDashboard(transport: transport)
        let accountID = try Self.seedInboxAccount(on: dashboard, keyID: "key_old")

        try await dashboard.removeConnection(accountID: accountID)
        let state = try #require(dashboard.connectionStates().first { $0.accountID == accountID })
        #expect(state.isArchived)
    }

    @Test("结束 / 清空这家时吊销失败，本地一条都不动")
    func archiveAndPurgeAbortWhenRevokeFails() async throws {
        let transport = ScriptedInboxTransport()
        transport.setRevokeStatus(500)
        let dashboard = try Self.makeDashboard(transport: transport)
        let accountID = try Self.seedInboxAccount(on: dashboard, keyID: "key_old")

        await #expect(throws: InboxError.self) {
            try await dashboard.archiveMembership(.render)
        }
        await #expect(throws: InboxError.self) {
            try await dashboard.purgeMembership(.render)
        }
        let state = try #require(dashboard.connectionStates().first { $0.accountID == accountID })
        #expect(state.isLive)
        #expect(state.inboxIngestKeyID == "key_old")
    }

    @Test("查重读不出已存凭据时按可能重复处理，不放第二份进来")
    func collisionCheckFailsClosedOnUnreadableCredentials() throws {
        let credentials = TogglingCredentialStore()
        let dashboard = DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: credentials,
            clock: .design,
            inboxClient: .stub(),
            httpClient: StubHTTPClient()
        )
        let existing = AccountID(rawValue: UUID())
        try dashboard.applyConnection(
            accountID: existing,
            providerID: .deepseek,
            nickname: nil,
            identityHint: nil,
            remoteIdentityFingerprint: nil,
            fields: [CredentialField.apiKey.rawValue: "sk-existing"],
            snapshots: [],
            mode: .create
        )
        let incoming = [CredentialField.apiKey.rawValue: "sk-other"]

        // 读得出来：不同密钥不算重复，行为和以前一样。
        #expect(dashboard.collidingConnection(
            providerID: .deepseek, fingerprint: nil, fields: incoming, excluding: nil
        ) == nil)

        credentials.failsReads = true
        #expect(dashboard.collidingConnection(
            providerID: .deepseek, fingerprint: nil, fields: incoming, excluding: nil
        )?.accountID == existing)
    }

    static func makeDashboard(transport: ScriptedInboxTransport) throws -> DashboardModel {
        let credentials = InMemoryCredentialStore()
        try InboxMailboxStore.save(
            StoredInboxMailbox(mailbox: "mb_test", readKey: "tollr_test"),
            to: credentials
        )
        return DashboardModel(
            providers: [:],
            container: try PersistenceContainer.makeContainer(inMemory: true),
            credentials: credentials,
            clock: .design,
            inboxClient: InboxClient(transport: transport),
            httpClient: StubHTTPClient()
        )
    }

    static func seedInboxAccount(on dashboard: DashboardModel, keyID: String) throws -> AccountID {
        let id = AccountID(rawValue: UUID())
        try dashboard.applyInboxConnection(
            accountID: id,
            providerID: .render,
            nickname: nil,
            identityHint: nil,
            ingestKeyID: keyID,
            credentialReference: "credential.\(id.rawValue.uuidString)"
        )
        return id
    }
}

/// 按路由给罐装应答的信箱传输层。吊销的状态码、签 key 要不要卡住都能在测试里拨。
final class ScriptedInboxTransport: InboxTransport, Sendable {
    private struct State {
        var revokeStatus = 200
        var mintIsGated = false
        var mintRequests = 0
        var mintedCount = 0
        var revokedIDs: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func setRevokeStatus(_ status: Int) {
        state.withLock { $0.revokeStatus = status }
    }

    func setMintGated(_ gated: Bool) {
        state.withLock { $0.mintIsGated = gated }
    }

    var mintRequests: Int { state.withLock { $0.mintRequests } }
    var revokedIDs: [String] { state.withLock { $0.revokedIDs } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url ?? InboxEndpoint.origin
        let path = url.path()
        let method = request.httpMethod ?? "GET"
        let status: Int
        let body: String
        if method == "DELETE", path.hasPrefix("/v1/inbox/ingest-keys/") {
            let id = String(path.dropFirst("/v1/inbox/ingest-keys/".count))
            status = state.withLock { current in
                if current.revokeStatus == 200 { current.revokedIDs.append(id) }
                return current.revokeStatus
            }
            body = status == 200 ? #"{"ok":true}"# : #"{"error":"x"}"#
        } else if method == "POST", path == "/v1/inbox/ingest-keys" {
            state.withLock { $0.mintRequests += 1 }
            while state.withLock({ $0.mintIsGated }) {
                try await Task.sleep(for: .milliseconds(5))
            }
            let n = state.withLock { current in
                current.mintedCount += 1
                return current.mintedCount
            }
            status = 201
            body = #"{"ingestKey":"tolli_TEST_\#(n)","ingestKeyID":"key_new_\#(n)"}"#
        } else {
            status = 200
            body = #"{"ok":true}"#
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(body.utf8), response)
    }
}

/// 模拟钥匙串被锁：条目在，但读的时候抛。
final class TogglingCredentialStore: CredentialStore, @unchecked Sendable {
    struct Locked: Error {}

    private let backing = InMemoryCredentialStore()
    var failsReads = false

    func save(_ secret: String, reference: String) throws {
        try backing.save(secret, reference: reference)
    }

    func read(reference: String) throws -> String? {
        if failsReads { throw Locked() }
        return try backing.read(reference: reference)
    }

    func delete(reference: String) throws {
        try backing.delete(reference: reference)
    }

    func deleteAll() throws {
        try backing.deleteAll()
    }
}
