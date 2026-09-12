import Foundation

/// Worker 源编译在这里，不进 catalog、不远程下发。
/// 部署 `worker/` 之后把 `origin` 换成 Cloudflare 给的 URL。
///
/// 这个 host 必须出现在 `MeterProviders.OutboundHosts`。两边不能互相
/// import，靠 `OutboundHostsTests` 锁死。
///
/// 打赏和读数信箱共用同一个 Worker（同 origin、不同路径），所以
/// `MeterInbox.InboxEndpoint.origin` 必须和这里一模一样，靠 `InboxEndpointTests` 锁。
public enum TipWorkerEndpoint: Sendable {
    public static let origin = URL(string: "https://api.tollcat.app")!

    public static var tipURL: URL {
        origin.appending(path: "v1/tip")
    }
}
