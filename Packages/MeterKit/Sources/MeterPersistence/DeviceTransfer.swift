import Foundation
import SwiftData
import MeterCore

/// 把接入、凭据、手动订阅、当月手填和偏好打成加密包，或从加密包写回本机。
/// 历史 Snapshot 不进包：重新刷一次就有了，落地密文越小越好。
/// 手填刷不回来，当月最新那一条进包。
///
/// 落盘字段增减必须过 `DeviceTransferCoverageTests`：要么接到载荷上，
/// 要么写进「不装」名单。提交闸扫同一份名单。漏写会静默丢数据——
/// `quantity` 这种带默认值的参数，编译器不会提醒。
public enum DeviceTransfer: Sendable {
    public static func makeExport(
        container: ModelContainer,
        credentials: any CredentialStore,
        now: Date,
        calendar: Calendar,
        code: TransferCode = .generate()
    ) throws -> TransferExport {
        let payload = try collect(
            container: container,
            credentials: credentials
        )
        let plaintext = try encodePayload(payload)
        let sealed = try TransferCryptor.seal(
            plaintext: plaintext,
            password: code.rawValue,
            now: now,
            lifetime: TransferLifetime.duration
        )
        return TransferExport(code: code, fileBytes: sealed.fileBytes, notAfter: sealed.notAfter)
    }

    public static func applyImport(
        fileBytes: Data,
        code: TransferCode,
        container: ModelContainer,
        credentials: any CredentialStore,
        now: Date,
        calendar: Calendar
    ) throws {
        let plaintext = try TransferCryptor.open(
            fileBytes: fileBytes,
            password: code.rawValue,
            now: now
        )
        let payload = try decodePayload(plaintext)
        try apply(
            payload,
            container: container,
            credentials: credentials,
            calendar: calendar
        )
    }

    static func encodePayload(_ payload: TransferPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(payload)
        } catch {
            throw TransferExportError.encodingFailed
        }
    }

    static func decodePayload(_ data: Data) throws -> TransferPayload {
        let payload: TransferPayload
        do {
            payload = try JSONDecoder().decode(TransferPayload.self, from: data)
        } catch {
            throw TransferImportError.invalidFile
        }
        guard payload.schemaVersion == TransferPayload.currentSchemaVersion else {
            throw TransferImportError.unsupportedPayloadSchema
        }
        return payload
    }

    static func collect(
        container: ModelContainer,
        credentials: any CredentialStore
    ) throws -> TransferPayload {
        let context = ModelContext(container)
        let configs = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        var connections: [TransferConnection] = []
        connections.reserveCapacity(configs.count)
        for record in configs.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            // 结束过的接入凭据已经删了，读出来必然是空。不要为此整包失败。
            let raw = record.archivedAt == nil
                ? try credentials.read(reference: record.credentialReference)
                : nil
            let fields = try raw.map(CredentialFieldsCodec.decode) ?? [:]
            connections.append(
                TransferConnection(
                    // 坏接入行整次导出失败：打成全零 UUID 带走等于把损坏搬到新机器。
                    accountID: try record.domainAccountID(),
                    providerID: record.providerID,
                    nickname: record.nickname,
                    identityHint: record.identityHint,
                    remoteIdentityFingerprint: record.remoteIdentityFingerprint,
                    isEnabled: record.isEnabled,
                    // 结束过的接入照样进包：新机器上它仍该出现在「历史服务」里，
                    // 不带就等于换台设备就把那段历史抹了。
                    archivedAt: record.archivedAt,
                    sortIndex: record.sortIndex,
                    credentialReference: record.credentialReference,
                    includeInGlobalRefresh: record.includeInGlobalRefresh,
                    credentialFields: fields,
                    usesInbox: record.usesInbox,
                    inboxIngestKeyID: record.inboxIngestKeyID
                )
            )
        }

        let subscriptionRecords = try context.fetch(FetchDescriptor<SubscriptionRecord>())
        var subscriptions: [TransferSubscription] = []
        subscriptions.reserveCapacity(subscriptionRecords.count)
        for record in subscriptionRecords {
            guard let period = SubscriptionPeriod(rawValue: record.periodRaw) else {
                throw TransferExportError.unreadableSubscription
            }
            subscriptions.append(
                TransferSubscription(
                    name: record.name,
                    amount: Money(usd: record.amountUSD),
                    period: period,
                    anchorYear: record.anchorYear,
                    anchorMonth: record.anchorMonth,
                    anchorDay: record.anchorDay,
                    endYear: record.endYear,
                    endMonth: record.endMonth,
                    endDay: record.endDay,
                    accountID: record.accountIDRaw.flatMap(UUID.init(uuidString:)).map(AccountID.init(rawValue:)),
                    providerID: record.providerIDRaw.map(ProviderID.init(rawValue:)),
                    // 有默认值，漏写会变成 1 份，总额还在、编辑页上的 ×N 没了。
                    quantity: record.quantity ?? 1
                )
            )
        }

        let stored = (try? AppPreferencesRecord.load(from: context)) ?? .default
        let preferences = TransferPreferences(
            includeAWSInGlobalRefresh: stored.includeAWSInGlobalRefresh,
            isReminderEnabled: stored.isReminderEnabled,
            reminderSchedule: stored.reminderSchedule,
            appearanceRaw: stored.appearance.rawValue,
            hasCompletedOnboarding: stored.hasCompletedOnboarding,
            providerHistoryRangeRaw: stored.providerHistoryRange.rawValue,
            hidesCat: stored.hidesCat,
            refreshesUsageOnActivate: stored.refreshesUsageOnActivate,
            displayCurrency: stored.displayCurrency,
            seenUsageGuideIDs: stored.seenUsageGuideIDs,
            dashboardLayout: stored.dashboardLayout,
            lastSeenWhatsNewVersion: stored.lastSeenWhatsNewVersion
        )

        // 信箱不属于任何一家 provider，不带上就是换设备后静默失效。
        let mailbox = InboxMailboxStore.load(from: credentials).map {
            TransferMailbox(mailbox: $0.mailbox, readKey: $0.readKey)
        }

        let membershipRecords = try context.fetch(FetchDescriptor<ProviderMembershipRecord>())
        var memberships = membershipRecords.map(\.membership)
        let memberIDs = Set(memberships.map(\.providerID))
        for connection in connections where !memberIDs.contains(connection.providerID) {
            memberships.append(
                ProviderMembership(providerID: connection.providerID, sortIndex: memberships.count)
            )
        }
        memberships.sort { $0.sortIndex < $1.sortIndex }

        let usageRecords = try context.fetch(FetchDescriptor<ManualUsageRecord>())
        let manualUsages = try usageRecords.map { try $0.transferItem() }

        return TransferPayload(
            connections: connections,
            memberships: memberships,
            subscriptions: subscriptions,
            preferences: preferences,
            mailbox: mailbox,
            manualUsages: manualUsages
        )
    }

    /// 导入前把整包**先解干净**。
    ///
    /// 这一步在动任何东西之前做，因为 `apply` 的第一件事就是删凭据——而 Keychain
    /// 不在 SwiftData 的事务里，删掉就是删掉了。等到走到订阅那一段才发现包有问题
    /// 抛 `invalidFile`，数据库整块回滚，Keychain 却不会：本机原来的接入全都还在
    /// 列表里，凭据一个不剩，而且没有任何一步能把它们要回来。
    ///
    /// 所以规矩是：**会抛的事全部发生在会毁的事之前。**
    /// Keychain 的服务/账号字段不是无限长；引用本身也从来不该是一大段文本。
    static let maxCredentialReferenceLength = 256

    private static func validated(
        _ payload: TransferPayload,
        calendar: Calendar
    ) throws -> (
        subscriptions: [MonthlySubscription],
        manualUsages: [(item: TransferManualUsage, amount: Money, kind: ProviderKind)]
    ) {
        // 包的内容全部来自文件，认证只证明「持有转移码的人做的」，不证明内容合理。
        // 自造一份合法 .tollcat 是低门槛的，所以形状要在落盘前核。
        var seenAccountIDs = Set<AccountID>()
        for connection in payload.connections {
            let reference = connection.credentialReference
            // 固定槽位不许被接入行的引用占掉：那会让一次导入顺手换掉目的地的信箱密钥。
            guard reference != InboxMailboxStore.credentialReference else {
                throw TransferImportError.invalidFile
            }
            guard !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  reference.count <= maxCredentialReferenceLength else {
                throw TransferImportError.invalidFile
            }
            // accountIDRaw 在库里有唯一约束。重复的留到 save 才炸，等于把一次
            // 可预见的输入错误变成半途回滚。
            guard seenAccountIDs.insert(connection.accountID).inserted else {
                throw TransferImportError.invalidFile
            }
        }

        var subscriptions: [MonthlySubscription] = []
        subscriptions.reserveCapacity(payload.subscriptions.count)
        for item in payload.subscriptions {
            guard let anchorDate = item.anchorDate(calendar: calendar),
                  let amount = item.money else {
                throw TransferImportError.invalidFile
            }
            subscriptions.append(
                MonthlySubscription(
                    name: item.name,
                    amount: amount,
                    period: item.period,
                    anchorDate: anchorDate,
                    endDate: item.endDate(calendar: calendar),
                    accountID: item.accountID,
                    providerID: item.providerID,
                    quantity: item.quantity
                )
            )
        }
        var manualUsages: [(item: TransferManualUsage, amount: Money, kind: ProviderKind)] = []
        manualUsages.reserveCapacity(payload.manualUsages.count)
        for item in payload.manualUsages {
            guard let amount = item.money else {
                throw TransferImportError.invalidFile
            }
            // kind 认不出**不算坏包**：旧包根本没有这一键（解码时补成 `.usage`，
            // 正是旧包写死的那一个），新包多一种 kind 也不该让整包被拒。
            // 归一走 `manualEntryKind`——手填只有 `currentSpendUSD` 一格装得下。
            let kind = (ProviderKind(rawValue: item.kindRaw) ?? .usage).manualEntryKind
            manualUsages.append((item, amount, kind))
        }
        return (subscriptions, manualUsages)
    }

    private static func apply(
        _ payload: TransferPayload,
        container: ModelContainer,
        credentials: any CredentialStore,
        calendar: Calendar
    ) throws {
        // 先验后毁。往下每一步都可能把本机的东西删掉，包括 Keychain 里那些
        // 回不来的凭据，所以整包能不能解必须在这一行之前问完。
        let checked = try validated(payload, calendar: calendar)
        let context = ModelContext(container)

        // **Keychain 和 SwiftData 不在一个事务里**，所以次序要保证任何一步失败都不会
        // 留下「库里有接入、钥匙却没了」的状态：
        //
        // 1. Keychain 只做**加**：新凭据。按 reference 幂等覆盖——库这边之后回滚了，
        //    本机原有的接入照旧有钥匙（同一个账号的钥匙被同一位用户的另一份覆盖，
        //    最坏是再导一次）。
        //
        //    **信箱不在这一步。** 上面那句「最坏是再导一次」只对一家一个的账单凭据
        //    成立：那种 reference 撞上了说明是同一个账号。`inbox.mailbox` 是**固定
        //    槽位**，任何一份包都会撞它——自造一份认证得过的 .tollcat 诱导受害者导入，
        //    随后 save 因 accountIDRaw 唯一约束抛错回滚，界面报「导入失败」，
        //    可目的地的信箱 read key 已经被换成攻击者的，且回滚还不回来。
        //    所以它挪到 save 成功之后写，并且先留一份旧值好在失败时还原。
        // 2. 库整份换掉，末尾一次 save。抛错就整块回滚，Keychain 里多出来的几条新钥匙
        //    没有行引用它们，无害。
        // 3. save 成了才删旧钥匙、清旧信箱。这一步失败只是 Keychain 里多留一条没人引用的
        //    钥匙（`StoreReset.deleteAll` 会一起清），不能让它把已经成功的导入报成失败。
        for connection in payload.connections where connection.archivedAt == nil {
            // 结束过的接入不写 Keychain：包里那份本来就是空的，
            // 写进去等于在新机器上凭空造一条空凭据。
            let encoded = try CredentialFieldsCodec.encode(connection.credentialFields)
            try credentials.save(encoded, reference: connection.credentialReference)
        }
        // 导入前目的地那份信箱，失败时用来还原。
        let previousMailbox = InboxMailboxStore.load(from: credentials)

        let existingConfigs = try context.fetch(FetchDescriptor<ProviderConfigRecord>())
        let keptReferences = Set(payload.connections.map(\.credentialReference))
        let staleReferences = existingConfigs
            .map(\.credentialReference)
            .filter { !keptReferences.contains($0) }
        for record in existingConfigs {
            context.delete(record)
        }

        let existingMemberships = try context.fetch(FetchDescriptor<ProviderMembershipRecord>())
        for record in existingMemberships {
            context.delete(record)
        }
        // 导出侧 collect 已保证每个 connection 都有 membership，这里照单全收。
        for membership in payload.memberships {
            try ProviderMembershipStore.insertExact(membership, in: context)
        }

        for connection in payload.connections {
            _ = try ProviderConfigStore.insert(
                accountID: connection.accountID,
                providerID: connection.providerID,
                nickname: connection.nickname,
                identityHint: connection.identityHint,
                remoteIdentityFingerprint: connection.remoteIdentityFingerprint,
                isEnabled: connection.isEnabled,
                // 包里带的是瞬间；落到本机按本机日历重记「结束那一天」。
                archived: connection.archivedAt.map { ArchivedStamp(at: $0, calendar: calendar) },
                credentialReference: connection.credentialReference,
                includeInGlobalRefresh: connection.includeInGlobalRefresh,
                usesInbox: connection.usesInbox,
                inboxIngestKeyID: connection.inboxIngestKeyID,
                lastSuccessfulRefreshAt: nil,
                placement: .exact(connection.sortIndex),
                in: context
            )
        }

        for record in try context.fetch(FetchDescriptor<SubscriptionRecord>()) {
            context.delete(record)
        }
        for domain in checked.subscriptions {
            context.insert(SubscriptionRecord(domain: domain, calendar: calendar))
        }

        for record in try context.fetch(FetchDescriptor<ManualUsageRecord>()) {
            context.delete(record)
        }
        for (item, amount, kind) in checked.manualUsages {
            _ = try ManualUsageStore.upsert(
                accountID: item.accountID,
                providerID: item.providerID,
                periodYear: item.periodYear,
                periodMonth: item.periodMonth,
                amount: amount,
                enteredAt: item.enteredAt,
                // kind 随包走。以前这条路写死 `.usage`，于是 `.planAndUsage`
                // 那几家导进来之后和源设备算出的钱不一样。
                kind: kind,
                in: context
            )
        }

        // 包里不带历史。目的地残留的快照会把两台设备的数字搅在一起。
        for record in try context.fetch(FetchDescriptor<SnapshotRecord>()) {
            context.delete(record)
        }
        // 账本是快照的派生物，快照整份换掉它也得走——而且在**同一个 save** 里：
        // 否则导入完的第一帧显示的是旧机器那份账，异步重折之后才跳到对的数。
        MonthlyLedgerStore.purgeWithoutSaving(in: context)
        for record in try ManualUsageStore.all(in: context) {
            try SnapshotWriter.apply(record.snapshot(calendar: calendar), to: context, calendar: calendar)
        }

        let preferences = AppPreferences(
            includeAWSInGlobalRefresh: payload.preferences.includeAWSInGlobalRefresh,
            isDemoModeEnabled: false,
            isDemoBannerDismissed: false,
            isReminderEnabled: payload.preferences.isReminderEnabled,
            reminderSchedule: payload.preferences.reminderSchedule,
            appearance: AppearancePreference(rawValue: payload.preferences.appearanceRaw) ?? .system,
            hasCompletedOnboarding: payload.preferences.hasCompletedOnboarding,
            providerHistoryRange: ProviderHistoryRange(
                rawValue: payload.preferences.providerHistoryRangeRaw
            ) ?? .default,
            hidesCat: payload.preferences.hidesCat,
            refreshesUsageOnActivate: payload.preferences.refreshesUsageOnActivate,
            displayCurrency: payload.preferences.displayCurrency,
            seenUsageGuideIDs: payload.preferences.seenUsageGuideIDs,
            // 版式随人走：钉出的账号和 connections 是同一批 AccountID，搬过去仍然对得上。
            // 旧包没有这一项就落产品默认。
            dashboardLayout: payload.preferences.dashboardLayout ?? .default,
            // 「看到哪一版」随人走：换机器不该把同一段说明再看一遍。旧包没有就当没记过。
            lastSeenWhatsNewVersion: payload.preferences.lastSeenWhatsNewVersion ?? ""
            // dashboardFilter 刻意**不搬**，落到产品默认（仅从量、全部账号）。
            //
            // 迁移包里不带它是有意的：筛选是一种临时看法，不是数据。新机器
            // 第一次打开就该看见全部账单，而不是继承上一台某次调完忘了收的取景框。
            // 而且包里也不带快照历史，往前翻月份在新机器上本来就没有数。
        )
        do {
            // 这一句里的 context.save() 是整份导入的提交点。
            try AppPreferencesRecord.save(preferences, to: context)
        } catch {
            // 库回滚了，Keychain 里多出来的几条新凭据没有行引用它们，无害；
            // 信箱还没动过，所以这里没有要还原的东西。
            throw error
        }

        // 提交成功，才动固定槽位的信箱。写失败就把导入前那份放回去——
        // 绝不能让目的地停在「旧的没了、新的也没写上」的状态。
        if let mailbox = payload.mailbox {
            do {
                try InboxMailboxStore.save(
                    StoredInboxMailbox(mailbox: mailbox.mailbox, readKey: mailbox.readKey),
                    to: credentials
                )
            } catch {
                if let previousMailbox {
                    try? InboxMailboxStore.save(previousMailbox, to: credentials)
                }
                throw error
            }
        }

        // 库落定了，才动 Keychain 里旧的东西（见上面那段次序）。
        // 目的地原本的信箱要清掉：包里没带信箱却留着本机那个，会让导入过来的信箱
        // provider 去读一个不属于它的信箱。包里带了的话上面已经覆盖过。
        for reference in staleReferences {
            try? credentials.delete(reference: reference)
        }
        if payload.mailbox == nil {
            try? InboxMailboxStore.clear(from: credentials)
        }
    }
}
