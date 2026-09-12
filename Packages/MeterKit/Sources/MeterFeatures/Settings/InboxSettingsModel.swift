import Foundation
import Observation
import MeterCore
import MeterInbox
import MeterProviders

/// 设置 → 读数信箱。管信箱本身和那几把投递 key。
@MainActor
@Observable
final class InboxSettingsModel {
    private(set) var mailbox: String?
    private(set) var keys: [IngestKeyInfo] = []
    private(set) var isLoading = false
    private(set) var failure: InboxError?
    /// 刚签出来的那把。只显示这一次，离开这一页就没了。
    private(set) var freshKey: IssuedIngestKey?
    var isConfirmingDelete = false
    var copyToken = 0

    private let inbox: InboxAccount
    /// 删信箱的确认框要点名受影响的服务，从这里读接入列表。
    private let connections: () -> [ProviderConnectionState]
    let calendar: Calendar

    convenience init(dashboard: DashboardModel) {
        self.init(
            inbox: dashboard.inbox,
            connections: { dashboard.connectionStates() },
            calendar: dashboard.clock.calendar
        )
    }

    init(
        inbox: InboxAccount,
        connections: @escaping () -> [ProviderConnectionState],
        calendar: Calendar
    ) {
        self.inbox = inbox
        self.connections = connections
        self.calendar = calendar
        // 本地就能知道有没有信箱。等 .task 再读会先闪一帧空态。
        mailbox = inbox.mailbox()?.mailbox
    }

    var hasInbox: Bool { mailbox != nil }

    /// 删信箱会让这几家立刻断供。确认框要点名，不做静默破坏。
    var affectedProviders: [String] {
        connections()
            .filter { $0.isLive && $0.usesInbox }
            .compactMap { ProviderCatalog.descriptor(id: $0.providerID)?.displayName }
    }

    func load() async {
        guard let stored = inbox.mailbox() else {
            mailbox = nil
            keys = []
            return
        }
        mailbox = stored.mailbox
        isLoading = true
        failure = nil
        defer { isLoading = false }
        do {
            keys = try await inbox.ingestKeys()
        } catch let error as InboxError {
            failure = error
        } catch {
            failure = InboxError(code: .unreachable)
        }
    }

    /// 签新的不吊销旧的——轮换是「签新的 → 改完脚本 → 吊销旧的」。
    func mintKey() async {
        guard hasInbox else { return }
        isLoading = true
        failure = nil
        defer { isLoading = false }
        do {
            freshKey = try await inbox.provisionKey(
                label: String(localized: L("新脚本"))
            )
            keys = (try? await inbox.ingestKeys()) ?? keys
        } catch let error as InboxError {
            failure = error
        } catch {
            failure = InboxError(code: .unreachable)
        }
    }

    func revokeKey(id: String) async {
        isLoading = true
        failure = nil
        defer { isLoading = false }
        do {
            try await inbox.revokeKey(id: id)
            if freshKey?.id == id { freshKey = nil }
            keys = (try? await inbox.ingestKeys()) ?? keys.filter { $0.id != id }
        } catch let error as InboxError {
            failure = error
        } catch {
            failure = InboxError(code: .unreachable)
        }
    }

    func deleteInbox() async {
        isLoading = true
        failure = nil
        defer { isLoading = false }
        do {
            try await inbox.deleteInbox()
            mailbox = nil
            keys = []
            freshKey = nil
        } catch let error as InboxError {
            failure = error
        } catch {
            failure = InboxError(code: .unreachable)
        }
    }

    func copyFreshKey() {
        guard let freshKey else { return }
        SystemClipboard.copy(freshKey.secret)
        copyToken += 1
    }

    func dismissFreshKey() {
        freshKey = nil
    }

    static func preview(hasInbox: Bool = true) -> InboxSettingsModel {
        let model = InboxSettingsModel(dashboard: .preview)
        if hasInbox {
            model.mailbox = "mb_preview_abcdef"
            model.keys = [
                IngestKeyInfo(
                    id: "key_1",
                    label: "Render 抓取",
                    createdAt: Date(timeIntervalSince1970: 1_785_600_000),
                    lastUsedAt: Date(timeIntervalSince1970: 1_787_000_000)
                ),
                IngestKeyInfo(
                    id: "key_2",
                    label: "Expo 抓取",
                    createdAt: Date(timeIntervalSince1970: 1_786_600_000),
                    lastUsedAt: nil
                ),
            ]
        }
        return model
    }
}
