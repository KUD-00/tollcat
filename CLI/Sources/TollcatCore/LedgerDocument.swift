struct LedgerDocument: Codable, Equatable, Sendable {
    var schema: Int
    var snapshots: [LedgerSnapshot]
    var memberships: [LedgerMembership]
    var accounts: [LedgerAccount]
    var subscriptions: [LedgerSubscription]

    static func empty() -> LedgerDocument {
        LedgerDocument(
            schema: LedgerSchema.version,
            snapshots: [],
            memberships: [],
            accounts: [],
            subscriptions: []
        )
    }
}
