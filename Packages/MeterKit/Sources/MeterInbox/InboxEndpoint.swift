import Foundation

/// Worker 源编译在这里，不进 catalog、不远程下发。理由和 `TipWorkerEndpoint`
/// 一样：远程可改的地址等于把用户的读数投递到别人家。
///
/// 和打赏共用同一个 Worker（同一个 origin，不同路径）。两个模块不能互相
/// import，所以 origin 在两边各写一份，靠 `InboxEndpointTests` 锁死相等。
/// 这个 host 也必须出现在 `MeterProviders.OutboundHosts`，靠 `OutboundHostsTests` 锁。
public enum InboxEndpoint: Sendable {
    public static let origin = URL(string: "https://api.tollcat.app")!

    public static var inboxURL: URL {
        origin.appending(path: "v1/inbox")
    }

    public static var ingestKeysURL: URL {
        origin.appending(path: "v1/inbox/ingest-keys")
    }

    public static func ingestKeyURL(id: String) -> URL {
        ingestKeysURL.appending(path: id)
    }

    public static var readingsURL: URL {
        origin.appending(path: "v1/readings")
    }
}
