import Foundation
import MeterCore

/// 「什么变了」的最小描述。派生缓存的钥匙统一从这里取。
///
/// ## 为什么不是一个数
///
/// 它以前是 `DashboardModel.presentationToken`，一个每次重算加一的 `Int`。
/// 那个数把**哪一家变了**这个信息扔掉了：全局刷新时十几家陆续回来，每回来一条
/// 它就加一，于是正在看的那一页——哪怕和刚回来的那家毫无关系——十几个派生缓存
/// 一起作废，在主线程上重算一遍。
///
/// 实测（12 家接入 · 636 条读数）：一次亮屏刷新让详情页重算 **26 遍**、
/// 占用主线程 **1620ms**，而其中真正该重算的只有一遍。缓存不是没写对，
/// 是钥匙的精度不够——它只能表达"有东西变了"，不能表达"变的不是你关心的那样东西"。
///
/// ## 两格分别是什么
///
/// - `global`：影响每一屏的那些变化。库里写过东西（加接入、手填、改订阅、删除、
///   历史回填）、显示货币、语言、历法 / 时区、目录换代、取景框。它们全部走
///   `DashboardModel.rebuildPresentation()` 这一条同步路径，都是用户一次点击一次的
///   操作，**本来就该让每一屏重算**，不在热路径上。
/// - `providers`：每家厂商自己的读数版本。**刷新只动这一格。**
///
/// 按厂商分格而不是按账号，理由是详情页本来就是一家一页：同一家的两份账号在同一页
/// 上，拆到账号粒度不会少一次重算，却要让每个消费方先算出"我关心哪几个账号"——
/// 而那件事本身要读 `connections`，于是钥匙又依赖上了它要保护的东西。
///
/// ## 纪律
///
/// 改这两格的地方**必须只有下面三处**，和以前"只有 `rebuildPresentation()` 能加那个数"
/// 是同一条纪律，只是精度高了一档：
///
/// | 格 | 谁能改 |
/// |---|---|
/// | `global` | `DashboardModel.rebuildPresentation()` |
/// | `providers` | `DashboardModel.refreshDidPersist(_:for:)`、`refreshDidMark(_:)` |
///
/// 绕过这三处的写路径会让缓存吐旧数字，表现和以前漏掉 `historyRange` 一模一样：
/// 不崩、不报错，屏幕上那个数停在上一次。`ArchitectureGuardrailTests` 里
/// `presentationRevisionHasOneWriter` 按字面量盯着这一条。
struct PresentationRevision: Hashable, Sendable {
    private(set) var global = 0
    private(set) var providers: [ProviderID: Int] = [:]

    mutating func noteGlobalChange() {
        global &+= 1
    }

    mutating func noteReading(for providerID: ProviderID) {
        providers[providerID, default: 0] &+= 1
    }

    /// 一屏只关心自己那一家。钥匙里只留它那一格。
    func scoped(to providerID: ProviderID) -> ScopedPresentationRevision {
        ScopedPresentationRevision(global: global, provider: providers[providerID] ?? 0)
    }
}

/// 一家厂商那一屏的派生缓存钥匙。
///
/// **是一个值，不是一个数。** 和 `MemoKey` 的用意一样：有第二个输入
/// （`historyRange.granularity` / `breakdownGrouping`）的仍然必须自己写进钥匙，
/// 漏掉一样的表现是那个数停在上一个档位。
struct ScopedPresentationRevision: Hashable, Sendable {
    var global: Int
    var provider: Int
}
