import Foundation

/// 一个信箱的两把 key。
///
/// **分成两把是这个设计的关键。** 投递 key 会躺在用户的 cron、CI、
/// browser-use 脚本里，它一定会泄露；所以它只能写。读 key 进 Keychain，
/// 永不显示给用户，也永不离开设备。
///
/// 服务端只存两把 key 的 SHA-256，丢了找不回来，只能轮换。
public struct InboxCredentials: Hashable, Sendable {
    /// 公开标识，不是密钥。用来在日志和界面上指代这个信箱。
    public var mailbox: String
    /// 取回读数用。进 Keychain。
    public var readKey: String

    public init(mailbox: String, readKey: String) {
        self.mailbox = mailbox
        self.readKey = readKey
    }
}

/// 新建信箱时服务端唯一一次把两把 key 都交出来。
///
/// `ingestKey` 只在这一刻存在于内存里：展示给用户复制走之后就丢掉，
/// **不要存进 Keychain**。设备上留着它没有任何用途，只是多一个泄露面。
public struct InboxProvisioning: Hashable, Sendable {
    public var credentials: InboxCredentials
    public var ingestKey: IssuedIngestKey

    public init(credentials: InboxCredentials, ingestKey: IssuedIngestKey) {
        self.credentials = credentials
        self.ingestKey = ingestKey
    }
}

/// 刚签出来的一把投递 key。`secret` 同样只此一次。
public struct IssuedIngestKey: Hashable, Sendable {
    public var id: String
    public var secret: String

    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }
}

/// 投递 key 的元数据。服务端只有哈希，所以这里永远没有 key 本身。
///
/// 一个脚本一把：`label` 记它是谁，`lastUsedAt` 用来提示「这把很久没投过了」。
public struct IngestKeyInfo: Hashable, Sendable, Identifiable {
    public var id: String
    public var label: String?
    public var createdAt: Date
    public var lastUsedAt: Date?

    public init(id: String, label: String?, createdAt: Date, lastUsedAt: Date?) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}

extension InboxCredentials: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "InboxCredentials(\(mailbox))" }
    public var debugDescription: String { description }
}

extension InboxProvisioning: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "InboxProvisioning(\(credentials.mailbox))" }
    public var debugDescription: String { description }
}

extension IssuedIngestKey: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { "IssuedIngestKey(\(id))" }
    public var debugDescription: String { description }
}
