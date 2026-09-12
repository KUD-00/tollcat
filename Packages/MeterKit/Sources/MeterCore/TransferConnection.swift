import Foundation

/// 一份接入的非密配置 + 凭据字段。字段值只应出现在加密后的密文里。
public struct TransferConnection: Codable, Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var nickname: String?
    public var identityHint: String?
    public var remoteIdentityFingerprint: String?
    public var isEnabled: Bool
    /// 结束这份接入的那一天。nil = 还在用。旧包没有这个键，解出来就是 nil。
    public var archivedAt: Date?
    public var sortIndex: Int
    public var credentialReference: String
    /// 三态照搬 `ProviderConfigRecord`：nil 是「跟 provider 默认走」，不是版本兼容。
    public var includeInGlobalRefresh: Bool?
    public var credentialFields: [String: String]
    /// 同上，nil 照原样搬过去。
    public var usesInbox: Bool?
    public var inboxIngestKeyID: String?

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String? = nil,
        identityHint: String? = nil,
        remoteIdentityFingerprint: String? = nil,
        isEnabled: Bool,
        archivedAt: Date? = nil,
        sortIndex: Int,
        credentialReference: String,
        includeInGlobalRefresh: Bool?,
        credentialFields: [String: String],
        usesInbox: Bool? = nil,
        inboxIngestKeyID: String? = nil
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.nickname = nickname
        self.identityHint = identityHint
        self.remoteIdentityFingerprint = remoteIdentityFingerprint
        self.isEnabled = isEnabled
        self.archivedAt = archivedAt
        self.sortIndex = sortIndex
        self.credentialReference = credentialReference
        self.includeInGlobalRefresh = includeInGlobalRefresh
        self.credentialFields = credentialFields
        self.usesInbox = usesInbox
        self.inboxIngestKeyID = inboxIngestKeyID
    }
}

extension TransferConnection: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        redactedDescription
    }

    public var debugDescription: String {
        redactedDescription
    }

    private var redactedDescription: String {
        let keys = credentialFields.keys.sorted().joined(separator: ", ")
        return "TransferConnection(\(providerID.rawValue); \(accountID.rawValue.uuidString); \(keys))"
    }
}
