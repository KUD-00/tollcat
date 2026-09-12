import Foundation

/// 一个已接入账号在展示层的样子：接没接、上次成功刷新是什么时候、叫什么。
///
/// 落盘记录（`ProviderConfigRecord`）不许离开它的 context，一律先换成这个值再往上传。
/// 住在 MeterCore 是因为折算要认它：`DashboardContentsBuilder` 靠它把
/// 「AWS · 工作」这种多账号标题拼出来，而 widget 也要跑同一份折算。
public struct ProviderConnectionState: Equatable, Sendable {
    public var accountID: AccountID
    public var providerID: ProviderID
    public var nickname: String? = nil
    public var identityHint: String? = nil
    public var remoteIdentityFingerprint: String? = nil
    public var isEnabled: Bool
    /// 结束这份接入的那一天。**nil = 还在用。**
    ///
    /// 结束不是删除：凭据删掉、不再刷新、不再进本月账单，但记录和历史快照留着，
    /// 过去几个月的柱子不会跟着塌。删除才是「连历史一起抹掉」。
    public var archivedAt: Date? = nil
    public var sortIndex: Int = 0
    public var lastSuccessfulRefreshAt: Date? = nil
    public var credentialReference: String
    public var includeInGlobalRefresh: Bool
    /// 这家的数来自读数信箱，不是 App 自己取的。
    public var usesInbox: Bool = false
    public var inboxIngestKeyID: String? = nil

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String? = nil,
        identityHint: String? = nil,
        remoteIdentityFingerprint: String? = nil,
        isEnabled: Bool,
        archivedAt: Date? = nil,
        sortIndex: Int = 0,
        lastSuccessfulRefreshAt: Date? = nil,
        credentialReference: String,
        includeInGlobalRefresh: Bool,
        usesInbox: Bool = false,
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
        self.lastSuccessfulRefreshAt = lastSuccessfulRefreshAt
        self.credentialReference = credentialReference
        self.includeInGlobalRefresh = includeInGlobalRefresh
        self.usesInbox = usesInbox
        self.inboxIngestKeyID = inboxIngestKeyID
    }

    /// 这份接入已经结束了。
    public var isArchived: Bool { archivedAt != nil }

    /// 还在用的接入：刷新、筛选名单、服务列表行、构成图都只认它。
    ///
    /// 到处写 `isEnabled` 是不够的——结束的接入 `isEnabled` 仍是 true，
    /// 它只是不再计入本月。想拿「现在还在跑的那几份」一律用这个。
    public var isLive: Bool { isEnabled && !isArchived }
}
