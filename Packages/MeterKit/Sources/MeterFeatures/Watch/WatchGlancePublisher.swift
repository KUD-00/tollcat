#if os(iOS)
import Foundation
import SwiftData
import WatchConnectivity
import MeterCore
import MeterGlance
import MeterPersistence

/// 把「一眼」推给手表。
///
/// 手表上没有账本、没有凭据，也不出网：它看到的每一个数都是这里推过去的。
/// 所以这一头只做三件事——库写完之后推一份、手表开 App 时回一份、配对状态变了补一份。
///
/// 两条通道分开用：`applicationContext` 只留最新一份、不限次数，每次都发；
/// 复杂功能那条（`transferCurrentComplicationUserInfo`）能把手表 App 从后台叫醒去刷表盘，
/// 但每天只有几十次，所以只在表盘上**看得出变化**时才花。
public final class WatchGlancePublisher: NSObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = WatchGlancePublisher()

    /// 连着写好几次库（一次刷新每家落一次盘）只推最后一份。
    static let coalesceDelay: TimeInterval = 2

    /// 下面几个可变字段只在这条队列上读写。
    private let queue = DispatchQueue(label: "com.zhechengqi.tollcat.watch-glance")
    private var source: (@Sendable () -> Glance?)?
    private var lastContext: Glance?
    private var lastComplication: Glance?
    private var pending: DispatchWorkItem?

    override private init() {
        super.init()
    }

    /// App 启动时接上库。没有配对手表的 iPhone、iPad 上什么都不做。
    public func start(container: ModelContainer, catalog: CatalogResolver, clock: MeterClock) {
        guard WCSession.isSupported() else { return }
        queue.async {
            self.source = { WatchGlanceSource.make(container: container, catalog: catalog, clock: clock) }
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// 库写完之后喊（`WidgetTimelineReloader` 里）。
    func storeDidChange() {
        queue.async {
            self.pending?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.publish() }
            self.pending = work
            self.queue.asyncAfter(deadline: .now() + Self.coalesceDelay, execute: work)
        }
    }

    /// 只在队列上调。
    private func publish() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              let glance = source?(),
              let message = try? GlanceCodec.message(glance)
        else {
            return
        }
        if lastContext.map({ !$0.carriesSameNews(as: glance) }) ?? true {
            try? session.updateApplicationContext(message)
            lastContext = glance
        }
        if session.isComplicationEnabled,
           session.remainingComplicationUserInfoTransfers > 0,
           Self.changesTheFace(from: lastComplication, to: glance) {
            session.transferCurrentComplicationUserInfo(message)
            lastComplication = glance
        }
    }

    /// 表盘上看得出来的变化：数变了、跨月了，或者手表那份已经旧到在说「几小时前更新」。
    /// 只是刷新时间往后挪了几分钟、数一分没变，就不花复杂功能的额度；
    /// 只有手表 App 里的服务列表 / 详情变了也不花——那些走 applicationContext 就够。
    static func changesTheFace(from previous: Glance?, to next: Glance) -> Bool {
        guard let previous else { return true }
        if previous.faceContent != next.faceContent || previous.monthStart != next.monthStart {
            return true
        }
        guard let staleAt = previous.staleAt else { return next.lastRefreshAt != nil }
        return next.generatedAt >= staleAt
    }

    // MARK: WCSessionDelegate

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        queue.async { self.publish() }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}

    /// 换了一块手表：系统要求重新激活，新表那头从头推一份。
    public func sessionDidDeactivate(_ session: WCSession) {
        queue.async {
            self.lastContext = nil
            self.lastComplication = nil
        }
        WCSession.default.activate()
    }

    /// 刚装上手表 App、或者刚把复杂功能放上表盘。
    public func sessionWatchStateDidChange(_ session: WCSession) {
        queue.async {
            self.lastContext = nil
            self.lastComplication = nil
            self.publish()
        }
    }

    /// 手表开着 App 时来要一份最新的。
    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[GlanceCodec.requestKey] != nil else {
            replyHandler([:])
            return
        }
        nonisolated(unsafe) let reply = replyHandler
        queue.async {
            guard let glance = self.source?(), let answer = try? GlanceCodec.message(glance) else {
                reply([:])
                return
            }
            reply(answer)
        }
    }
}
#endif
