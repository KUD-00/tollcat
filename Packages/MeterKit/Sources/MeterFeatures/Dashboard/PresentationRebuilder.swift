import Foundation

/// 「什么时候把重算好的内容换上屏」这一件事。
///
/// ## 为什么单独一个类型
///
/// 它以前是 `DashboardModel` 上五个互相咬合的字段（上次上屏的时刻、跳过了没有、
/// 排着的补算、代号、节流间隔），零测试。刷新期间十家账号陆续回来，每一条都要
/// 重算十几块内容再让 SwiftUI 整页重画——不节流的话圆环的进场动画会被连着掐住；
/// 而节流一旦漏掉「跳过的那次要补回来」，最后一家的数字就永远不上屏。
///
/// 两条相反的错都长得很正常（一个是卡顿，一个是数字停在倒数第二家），所以这
/// 五个字段必须能单独测。
///
/// ## 代号是干什么的
///
/// 重算搬到后台线程算，算完回主线程赋值。等这一下的期间可能又请求过重算
/// （下一家回来了、用户连点了几颗筛选 chip），那份算好的已经过期。
/// `beginBuild()` 发一个代号，回来时 `isCurrent(_:)` 说了不算就整份丢掉——
/// 丢掉不补也没关系：让它过期的那次重算自己会上屏。
@MainActor
final class PresentationRebuilder {
    /// 刷新中最短的重算间隔。450ms 的进场动画期间正好只让一次重算插进来。
    static let throttle = Duration.milliseconds(400)

    /// 真正的重算。节流只决定**什么时候**调它，不知道它算什么。
    private let rebuild: () async -> Void
    /// 上一次真的上屏的时刻。
    private var lastRebuildAt: ContinuousClock.Instant?
    /// 节流期间跳过了重算：补算任务和刷新收尾都看它，否则最后一家的数字不上屏。
    private var needsRebuild = false
    /// 节流期间排的补算。同一时刻只排一个。
    private var pendingTask: Task<Void, Never>?
    /// 每请求一次重算加一。见上面「代号是干什么的」。
    private var generation = 0

    init(rebuild: @escaping () async -> Void) {
        self.rebuild = rebuild
    }

    /// 开一次重算，拿一个代号。
    func beginBuild() -> Int {
        generation += 1
        return generation
    }

    /// 这个代号还是最新的那次吗。不是就把算好的丢掉。
    func isCurrent(_ token: Int) -> Bool {
        generation == token
    }

    /// 一次重算真的上屏了。
    func didBuild() {
        lastRebuildAt = .now
        needsRebuild = false
    }

    /// 刷新开跑：把计时器归零，第一条结果照样要等一个节流窗口。
    func noteRefreshWillStart() {
        lastRebuildAt = .now
    }

    /// 刷新路径的重算入口。窗口内最多上屏一次，被跳过的那次排一个补算。
    func requestThrottled() async {
        let now = ContinuousClock.now
        guard let lastRebuildAt, now - lastRebuildAt < Self.throttle else {
            await rebuild()
            return
        }
        needsRebuild = true
        guard pendingTask == nil else { return }
        let wait = Self.throttle - (now - lastRebuildAt)
        pendingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: wait)
            // 被 `flush()` 取消时什么都别碰：那边已经重算过、也已经把句柄清了。
            guard !Task.isCancelled, let self else { return }
            self.pendingTask = nil
            guard self.needsRebuild else { return }
            await self.rebuild()
        }
    }

    /// 刷新收尾：把排着的补算收掉，最后一家的数字立刻上屏。
    func flush() async {
        pendingTask?.cancel()
        pendingTask = nil
        guard needsRebuild else { return }
        await rebuild()
    }
}
