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
        do {
            let hadMailbox = dashboard.inbox.mailbox() != nil
            issuedKey = try await dashboard.inbox.provisionKey(
                label: String(localized: L("\(displayName) 抓取"))
            )
            createdMailboxThisSession = !hadMailbox
            mintedKeyThisSession = true
            phase = .issued
        } catch let error as InboxError {
            failure = error
            phase = .failed
        } catch {
            failure = InboxError(code: .unreachable)
            phase = .failed
        }
    }

    func retry() async {
        await discardPendingKey()
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
                try? await dashboard.inbox.revokeKey(id: oldKey)
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
        await discardPendingKey()
        phase = .idle
        failure = nil
    }

    private func discardPendingKey() async {
        guard mintedKeyThisSession, let issuedKey else { return }
        do {
            try await dashboard.inbox.revokeKey(id: issuedKey.id)
        } catch {
            TollCatLog.event("inbox", "revoke pending ingest key failed \(issuedKey.id) \(error)")
        }
        mintedKeyThisSession = false
        self.issuedKey = nil

        let hasInboxAccount = dashboard.connectionStates().contains { $0.usesInbox }
        if createdMailboxThisSession, !hasInboxAccount {
            try? await dashboard.inbox.deleteInbox()
            createdMailboxThisSession = false
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
