import Foundation
import Testing
@testable import MeterFeatures

/// 节流那五个字段以前是 `DashboardModel` 上的一台状态机，**零测试**。
/// 第二轮审视第 15 条：两条相反的错都长得很正常——一个是刷新期间卡顿，
/// 一个是最后一家的数字永远不上屏。
@MainActor
struct PresentationRebuilderTests {
    /// 数一数真正重算了几次。
    private final class Counter {
        var count = 0
    }

    private func make() -> (PresentationRebuilder, Counter) {
        let counter = Counter()
        let rebuilder = PresentationRebuilder {
            counter.count += 1
        }
        return (rebuilder, counter)
    }

    @Test("第一次请求立刻重算：没有上一次，就没有窗口可言")
    func firstRequestRunsImmediately() async {
        let (rebuilder, counter) = make()
        await rebuilder.requestThrottled()
        #expect(counter.count == 1)
    }

    @Test("窗口内连着三次只重算一次，flush 之后一定再算一次")
    func threeRequestsInsideTheWindowCollapseIntoOnePlusFlush() async {
        let (rebuilder, counter) = make()
        rebuilder.noteRefreshWillStart()
        for _ in 0..<3 {
            await rebuilder.requestThrottled()
        }
        // 窗口（400ms）内一次都没上屏——但「还欠一次」立着。
        #expect(counter.count == 0)

        await rebuilder.flush()
        // 补算收掉了，最后那一份数字上屏。
        #expect(counter.count == 1)
    }

    @Test("什么都没跳过时 flush 不多算一次")
    func flushIsANoOpWhenNothingWasSkipped() async {
        let (rebuilder, counter) = make()
        await rebuilder.requestThrottled()
        #expect(counter.count == 1)
        await rebuilder.flush()
        #expect(counter.count == 1)
    }

    @Test("代号：新的一次开跑之后，旧的那份算完回来就作废")
    func staleTokensAreRejected() {
        let (rebuilder, _) = make()
        let first = rebuilder.beginBuild()
        #expect(rebuilder.isCurrent(first))
        let second = rebuilder.beginBuild()
        #expect(rebuilder.isCurrent(second))
        #expect(!rebuilder.isCurrent(first))
    }

    @Test("上屏之后窗口重新开始：didBuild 之后紧接着一次请求会被节流")
    func didBuildStartsTheWindow() async {
        let (rebuilder, counter) = make()
        rebuilder.didBuild()
        await rebuilder.requestThrottled()
        #expect(counter.count == 0)
        await rebuilder.flush()
        #expect(counter.count == 1)
    }
}
