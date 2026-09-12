import Foundation

/// Android 没有 `LocalizedStringResource`；那边的 `L()` 原样返回 key，用途文案就是 String。
#if os(Android)
public typealias OutboundPurpose = String
#else
public typealias OutboundPurpose = LocalizedStringResource
#endif

/// 这一支域名归哪个壳。默认全端——只有某个壳独有的更新 / 分发通道才标出来。
///
/// 「声明过」和「这个壳会连」是两件事：出站脚本按全集扫源码里的 https:// 字面量
/// （字面量在哪个 target 里编译不改变它被声明过），关于页和运行时白名单按当前壳收窄。
public enum OutboundHostScope: Sendable, Hashable {
    /// iPhone / iPad / Mac 都可能连。
    case allPlatforms
    /// 只有 Mac 直发版会连：Sparkle 拉更新清单和更新包。
    /// iOS 与 App Store 版根本不链更新器，也就不发这种请求。
    case macDirectRelease
}

/// 一支出站声明：域名 + 用途 + 哪个壳会连。关于页直接渲染这一份，不要另抄一张表。
public struct OutboundHost: Sendable, Identifiable {
    public var host: String
    public var purpose: OutboundPurpose
    public var scope: OutboundHostScope

    public var id: String { host }

    /// 当前编译目标会不会连它。`OutboundHosts.visible` / `declaredHosts` 按它过滤。
    public var isActiveHere: Bool {
        switch scope {
        case .allPlatforms:
            true
        case .macDirectRelease:
            #if os(macOS)
            true
            #else
            false
            #endif
        }
    }

    public init(host: String, purpose: OutboundPurpose, scope: OutboundHostScope = .allPlatforms) {
        self.host = host
        self.purpose = purpose
        self.scope = scope
    }
}
