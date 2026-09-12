import Foundation
import SwiftData
import MeterCore

/// 结束这份接入的那一天，**两种形状一次算出**。
///
/// 落盘要存分量（结束月不能随时区挪位，见 `ProviderConfigRecord.archivedDay`），
/// 而旧行只有瞬间，所以两列都得写。分成两个参数传的话，迟早有一条路只填了一个，
/// 于是这个类型让它们只能来自同一个时刻 + 同一本日历。
public struct ArchivedStamp: Sendable, Hashable {
    public let at: Date
    public let day: String

    public init(at: Date, calendar: Calendar) {
        self.at = at
        self.day = DayKey(at, calendar: calendar).storageString
    }
}

/// 一份接入。密钥本身绝不进这一行，只留 Keychain 引用。
@Model
public final class ProviderConfigRecord {
    /// 每落一条快照都要按账号回写「上次成功刷新」，一次刷新每家一遍。
    #Index<ProviderConfigRecord>([\.accountIDRaw])

    @Attribute(.unique)
    public var accountIDRaw: String
    public var providerIDRaw: String
    public var nickname: String?
    public var identityHint: String?
    public var remoteIdentityFingerprint: String?
    public var isEnabled: Bool
    /// 结束这份接入的那一刻，**加分量列之前**写下的形状。只为读旧行留着。
    /// 结束会删掉 Keychain 里的凭据，但这一行和历史快照留着——
    /// 删行会让快照变成孤儿，展示层认不出它属于谁，过去几个月的数字跟着消失。
    public var archivedAt: Date?
    /// 结束这份接入的**那一天**（`DayKey.storageString`）。nil = 还在用，
    /// 或者是加这一列之前的旧行（那时回落到 `archivedAt`）。
    ///
    /// 存分量不存瞬间：这一天决定「结束月」，而「本地 8/31 23:30」在另一本
    /// 日历上是 9/1，那一家的最后一个月会整月挪位。存法和 `SubscriptionRecord`
    /// 的锚点一致——还原时落当天 12:00，避开夏令时和午夜边界。
    public var archivedDay: String?
    public var sortIndex: Int
    public var lastSuccessfulRefreshAt: Date?
    /// Keychain 的 account，不是密钥。
    public var credentialReference: String
    /// `nil` 表示跟 descriptor：要花钱取数的默认不进全局刷新。
    public var includeInGlobalRefresh: Bool?
    public var usesInbox: Bool?
    public var inboxIngestKeyID: String?

    public init(
        accountID: AccountID,
        providerID: ProviderID,
        nickname: String? = nil,
        identityHint: String? = nil,
        remoteIdentityFingerprint: String? = nil,
        isEnabled: Bool,
        archived: ArchivedStamp? = nil,
        sortIndex: Int,
        lastSuccessfulRefreshAt: Date? = nil,
        credentialReference: String,
        includeInGlobalRefresh: Bool? = nil,
        usesInbox: Bool? = nil,
        inboxIngestKeyID: String? = nil
    ) {
        self.accountIDRaw = accountID.rawValue.uuidString
        self.providerIDRaw = providerID.rawValue
        self.nickname = nickname
        self.identityHint = identityHint
        self.remoteIdentityFingerprint = remoteIdentityFingerprint
        self.isEnabled = isEnabled
        self.archivedAt = archived?.at
        self.archivedDay = archived?.day
        self.sortIndex = sortIndex
        self.lastSuccessfulRefreshAt = lastSuccessfulRefreshAt
        self.credentialReference = credentialReference
        self.includeInGlobalRefresh = includeInGlobalRefresh
        self.usesInbox = usesInbox
        self.inboxIngestKeyID = inboxIngestKeyID
    }

    public var readsFromInbox: Bool {
        usesInbox == true
    }

    public var providerID: ProviderID {
        ProviderID(providerIDRaw)
    }

    /// 解不出就抛，与 `SnapshotRecord.toDomain` 同一口径。全零回退会和
    /// 测试夹具 `fixture(0)` 撞车，还让坏行伪装成一份真账号。
    /// 落盘记录 → 展示层的连接状态。**只有这一处**——仪表盘和 widget 都从这里拿，
    /// 两边各写一遍映射，迟早有一边漏掉一个字段（然后 widget 上的名字就和 App 里不一样）。
    /// `calendar` 把 `archivedDay` 的分量还原成那一天的 12:00。
    /// 旧行没有分量列，回落到 `archivedAt` 那一刻。
    public func connectionState(calendar: Calendar) -> ProviderConnectionState? {
        guard let accountID = try? domainAccountID() else { return nil }
        let costsMoney = ProviderIdentity.known(providerID)?.costsMoneyToRefresh ?? false
        return ProviderConnectionState(
            accountID: accountID,
            providerID: providerID,
            nickname: nickname,
            identityHint: identityHint,
            remoteIdentityFingerprint: remoteIdentityFingerprint,
            isEnabled: isEnabled,
            archivedAt: archivedDate(in: calendar),
            sortIndex: sortIndex,
            lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
            credentialReference: credentialReference,
            includeInGlobalRefresh: includeInGlobalRefresh ?? !costsMoney,
            usesInbox: readsFromInbox,
            inboxIngestKeyID: inboxIngestKeyID
        )
    }

    /// 结束那一天在这本日历上的 12:00。分量列解不出（旧行 / 坏值）回落到旧列。
    func archivedDate(in calendar: Calendar) -> Date? {
        guard let archivedDay, let key = DayKey(storageString: archivedDay) else {
            return archivedAt
        }
        var components = DateComponents()
        components.year = key.year
        components.month = key.month
        components.day = key.day
        components.hour = 12
        return calendar.date(from: components) ?? archivedAt
    }

    public func domainAccountID() throws -> AccountID {
        guard let uuid = UUID(uuidString: accountIDRaw) else {
            throw PersistenceError.invalidStoredAccount(accountIDRaw)
        }
        return AccountID(rawValue: uuid)
    }

    /// 删接入时密钥必须一起走，否则设备上会留下孤儿凭据。
    public func deleteTogetherWithCredentials(
        in context: ModelContext,
        credentials: any CredentialStore
    ) throws {
        try credentials.delete(reference: credentialReference)
        context.delete(self)
    }

    /// 结束这份接入：凭据删掉，行留下。
    ///
    /// 凭据不能留——用户说的是「我不用这家了」，钥匙没有理由继续躺在 Keychain 里。
    /// 但行必须留：快照靠 `accountID` 找回自己属于谁，行没了它们就成孤儿，
    /// 过去几个月的账单会跟着塌掉一块。
    ///
    /// `calendar` 是落盘日历：结束的是**哪一天**，不是哪一刻（见 `archivedDay`）。
    public func archive(
        at date: Date,
        calendar: Calendar,
        credentials: any CredentialStore
    ) throws {
        guard archivedAt == nil, archivedDay == nil else { return }
        try credentials.delete(reference: credentialReference)
        let stamp = ArchivedStamp(at: date, calendar: calendar)
        archivedAt = stamp.at
        archivedDay = stamp.day
    }
}
