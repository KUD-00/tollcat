import Foundation

/// 跨设备迁移的明文载荷。只活在内存里，加密之前和之后都不落盘。
///
/// 不带历史 Snapshot：重新刷一次就有了，落地密文越小、装的东西越少越好。
public struct TransferPayload: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var connections: [TransferConnection]
    public var memberships: [ProviderMembership]
    public var subscriptions: [TransferSubscription]
    public var preferences: TransferPreferences
    /// 没用过信箱是 `null`，键必须在。缺键的包解不开。
    public var mailbox: TransferMailbox?
    /// 当月手填刷不回来，所以进包。
    public var manualUsages: [TransferManualUsage]

    public init(
        schemaVersion: Int = TransferPayload.currentSchemaVersion,
        connections: [TransferConnection],
        memberships: [ProviderMembership] = [],
        subscriptions: [TransferSubscription],
        preferences: TransferPreferences,
        mailbox: TransferMailbox? = nil,
        manualUsages: [TransferManualUsage] = []
    ) {
        self.schemaVersion = schemaVersion
        self.connections = connections
        self.memberships = memberships
        self.subscriptions = subscriptions
        self.preferences = preferences
        self.mailbox = mailbox
        self.manualUsages = manualUsages
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case connections
        case memberships
        case subscriptions
        case preferences
        case mailbox
        case manualUsages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        connections = try container.decode([TransferConnection].self, forKey: .connections)
        memberships = try container.decode([ProviderMembership].self, forKey: .memberships)
        subscriptions = try container.decode([TransferSubscription].self, forKey: .subscriptions)
        preferences = try container.decode(TransferPreferences.self, forKey: .preferences)
        mailbox = try container.decode(TransferMailbox?.self, forKey: .mailbox)
        manualUsages = try container.decode([TransferManualUsage].self, forKey: .manualUsages)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(connections, forKey: .connections)
        try container.encode(memberships, forKey: .memberships)
        try container.encode(subscriptions, forKey: .subscriptions)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(mailbox, forKey: .mailbox)
        try container.encode(manualUsages, forKey: .manualUsages)
    }
}
