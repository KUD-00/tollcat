import Foundation

/// 从不 insert。找不到账号 → `ProviderConfigStoreError.accountNotFound`。
/// 不改 accountID / providerID / credentialReference / sortIndex。
public struct ProviderConfigUpdate: Sendable, Equatable {
    /// `.none` 不改；`.some(nil)` 清空。
    public var nickname: String??
    public var identityHint: String??
    public var remoteIdentityFingerprint: String??
    public var isEnabled: Bool?
    public var lastSuccessfulRefreshAt: Date?
    public var includeInGlobalRefresh: Bool??
    public var usesInbox: Bool??
    public var inboxIngestKeyID: String??

    public init(
        nickname: String?? = nil,
        identityHint: String?? = nil,
        remoteIdentityFingerprint: String?? = nil,
        isEnabled: Bool? = nil,
        lastSuccessfulRefreshAt: Date? = nil,
        includeInGlobalRefresh: Bool?? = nil,
        usesInbox: Bool?? = nil,
        inboxIngestKeyID: String?? = nil
    ) {
        self.nickname = nickname
        self.identityHint = identityHint
        self.remoteIdentityFingerprint = remoteIdentityFingerprint
        self.isEnabled = isEnabled
        self.lastSuccessfulRefreshAt = lastSuccessfulRefreshAt
        self.includeInGlobalRefresh = includeInGlobalRefresh
        self.usesInbox = usesInbox
        self.inboxIngestKeyID = inboxIngestKeyID
    }
}
