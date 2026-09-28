import Foundation
import Observation
import MeterCore
import MeterInbox
import MeterProviders

/// 走读数信箱那几家的接入状态机。
///
/// 和普通向导最大的不同：**没有「测试连接」。** 用户这会儿还没写脚本，
/// 信箱里必然是空的。硬要测就只能测出失败，所以流程改成
/// 「拿到任务书 → 确认收好 → 接入 → 等第一次投递」。
@MainActor
@Observable
final class InboxHandoffModel {
    enum Phase: Hashable {
        case idle
        case provisioning
        case issued
        case failed
    }

    let providerID: ProviderID
    /// 接到已经手填过的那份用量上。nil 就是新开一份。
    private let attachingAccountID: AccountID?
    private(set) var phase: Phase = .idle
    private(set) var issuedKey: IssuedIngestKey?
    private(set) var failure: InboxError?
    var copyToken = 0
    var saveToken = 0
    var siblingNickname = ""
    var newNickname = ""

    private let dashboard: DashboardModel
    private var createdMailboxThisSession = false
    private var mintedKeyThisSession = false
    /// 每放弃一次（取消 / 重试）换一代。签 key 的 await 回来时代数变了，说明用户已经放弃了这一轮：
    /// 那把 key 要立刻吊销，页面也不能再推进到 `.issued`。
    private var provisionGeneration = 0
    /// 放弃之后才签回来、又没吊销成功的 key。下次放弃时接着吊销，不让它悄悄活下去。
    private var orphanedKeyIDs: [String] = []

    init(
        providerID: ProviderID,
        dashboard: DashboardModel,
        attachingAccountID: AccountID? = nil
    ) {
        self.providerID = providerID
        self.dashboard = dashboard
        self.attachingAccountID = attachingAccountID
        prepareNicknameDraft()
    }

    var displayName: String {
        ProviderCatalog.descriptor(id: providerID)?.displayName ?? providerID.rawValue
    }

    var colorKey: String {
        ProviderCatalog.descriptor(id: providerID)?.colorKey ?? providerID.rawValue
    }

    var siblingConnections: [ProviderConnectionState] {
        dashboard.connectionStates().filter {
            $0.providerID == providerID && $0.accountID != attachingAccountID
        }
    }

    var showsNicknameFields: Bool {
        attachingAccountID == nil && siblingConnections.count >= 1
    }

    var existingSibling: ProviderConnectionState? {
        siblingConnections.sorted { $0.sortIndex < $1.sortIndex }.first
    }

    var trimmedNewNickname: String {
        newNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSiblingNickname: String {
        siblingNickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var prompt: String {
        let title: String
        if showsNicknameFields, !trimmedNewNickname.isEmpty {
            title = "\(displayName) · \(trimmedNewNickname)"
        } else {
            title = displayName
        }
        return InboxPromptBuilder.prompt(
            providerID: providerID,
            displayName: title,
            now: dashboard.clock.now,
            calendar: dashboard.clock.calendar
        )
    }

    var canConnect: Bool {
        guard phase == .issued else { return false }
        if showsNicknameFields, trimmedNewNickname.isEmpty { return false }
        return true
    }

    /// 第一次进这一页时才建信箱 / 签 key。已有 mailbox 时仍 mint。
    func prepare() async {
        guard phase == .idle else { return }
        phase = .provisioning
        failure = nil
        prepareNicknameDraft()
        let generation = provisionGeneration
        do {
            let hadMailbox = dashboard.inbox.mailbox() != nil
            let key = try await dashboard.inbox.provisionKey(
                label: String(localized: L("\(displayName) 抓取"))
            )
            guard generation == provisionGeneration else {
                await revokeOrphanedKey(key)
                return
            }
            issuedKey = key
            createdMailboxThisSession = !hadMailbox
            mintedKeyThisSession = true
            phase = .issued
        } catch let error as InboxError {
            guard generation == provisionGeneration else { return }
            failure = error
            phase = .failed
        } catch {
            guard generation == provisionGeneration else { return }
            failure = InboxError(code: .unreachable)
            phase = .failed
        }
    }

    func retry() async {
        do {
            try await discardPendingKey()
        } catch {
            // 上一把没吊销掉就不签新的：停在失败态，让用户再点一次重试，
            // 不然手上会同时攥着两把都活着的 key，其中一把再也没人管。
            failure = (error as? InboxError) ?? InboxError(code: .unreachable)
            phase = .failed
            return
        }
        phase = .idle
        issuedKey = nil
        await prepare()
    }

    func copyPrompt() {
        SystemClipboard.copy(prompt)
        copyToken += 1
    }

    func copyIngestKey() {
        guard let issuedKey else { return }
        SystemClipboard.copy(issuedKey.secret)
        copyToken += 1
    }

    func connect() async throws {
        guard canConnect else { return }
        if issuedKey == nil {
            issuedKey = try await dashboard.inbox.provisionKey(
                label: String(localized: L("\(displayName) 抓取"))
            )
            mintedKeyThisSession = true
        }
        guard let issuedKey else { return }
        if let attachingAccountID {
            if let oldKey = dashboard.connectionStates()
                .first(where: { $0.accountID == attachingAccountID })?
                .inboxIngestKeyID,
               !oldKey.isEmpty {
                // 挂到已有账号上就是轮换：旧 key 确认死了才换上新的。吊销失败就抛，
                // 不 attach、不加 saveToken，新 key 留在手上等用户重试——
                // 否则界面说换好了，拿着旧 key 的人照样能往信箱里投。
                try await dashboard.revokeIngestKey(id: oldKey)
            }
            try dashboard.attachInbox(accountID: attachingAccountID, ingestKeyID: issuedKey.id)
            saveToken += 1
            return
        }
        let siblingToRename = showsNicknameFields ? existingSibling : nil
        let id = AccountID(rawValue: UUID())
        let reference = "credential.\(id.rawValue.uuidString)"
        try dashboard.applyInboxConnection(
            accountID: id,
            providerID: providerID,
            nickname: showsNicknameFields ? trimmedNewNickname : nil,
            identityHint: nil,
            ingestKeyID: issuedKey.id,
            credentialReference: reference
        )
        if let siblingToRename {
            let name = trimmedSiblingNickname.isEmpty
                ? String(localized: L("账号 1"))
                : trimmedSiblingNickname
            try dashboard.updateAccountNickname(name, for: siblingToRename.accountID)
        }
        saveToken += 1
    }

    /// 取消 / 失败：revoke 刚签的 key。仅本 session 新建的空信箱且还没有任何信箱账号才删 mailbox。
    func discardIfUnconnected() async {
        guard saveToken == 0 else { return }
        do {
            try await discardPendingKey()
        } catch {
            // 没吊销掉：key 和 phase 原样留着，再回到这一页看到的还是这把、还能接入或再取消一次，
            // 而不是本地先忘了它、服务端那把却一直有效。
            // 签到一半被放弃的那一轮已经作废（代数换过了），别让页面停在转圈上。
            if phase == .provisioning { phase = .idle }
            return
        }
        phase = .idle
        failure = nil
    }

    /// 吊销成功之前不清本地的 key：清了就再也没有机会收回服务端那把。
    private func discardPendingKey() async throws {
        provisionGeneration += 1
        for id in orphanedKeyIDs {
            try await dashboard.revokeIngestKey(id: id)
            orphanedKeyIDs.removeAll { $0 == id }
        }
        guard mintedKeyThisSession, let issuedKey else { return }
        try await dashboard.revokeIngestKey(id: issuedKey.id)
        mintedKeyThisSession = false
        self.issuedKey = nil

        let hasInboxAccount = dashboard.connectionStates().contains { $0.usesInbox }
        if createdMailboxThisSession, !hasInboxAccount {
            try? await dashboard.inbox.deleteInbox()
            createdMailboxThisSession = false
        }
    }

    /// 放弃之后才签回来的 key：不进 `issuedKey`、不推进 phase，直接吊销。
    /// 吊销失败记进 `orphanedKeyIDs`，下次放弃再试。
    private func revokeOrphanedKey(_ key: IssuedIngestKey) async {
        do {
            try await dashboard.revokeIngestKey(id: key.id)
        } catch {
            orphanedKeyIDs.append(key.id)
        }
    }

    private func prepareNicknameDraft() {
        guard showsNicknameFields, let sibling = existingSibling else { return }
        if siblingNickname.isEmpty {
            let existing = sibling.nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            siblingNickname = existing.isEmpty ? String(localized: L("账号 1")) : existing
        }
    }

    static func preview(
        providerID: ProviderID = .render,
        phase: Phase = .issued
    ) -> InboxHandoffModel {
        let model = InboxHandoffModel(providerID: providerID, dashboard: .preview)
        model.phase = phase
        if phase == .issued {
            model.issuedKey = IssuedIngestKey(id: "key_preview", secret: "tolli_PREVIEW_KEY_1234")
        }
        if phase == .failed {
            model.failure = InboxError(code: .unreachable)
        }
        return model
    }
}
