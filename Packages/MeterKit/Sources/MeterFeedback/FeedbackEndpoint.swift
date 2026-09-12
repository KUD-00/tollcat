import Foundation

/// Worker 源编译在这里，不进 catalog、不远程下发。
///
/// 这个 host 必须出现在 `MeterProviders.OutboundHosts`，而且必须和
/// `MeterTips.TipWorkerEndpoint.origin`、`MeterInbox.InboxEndpoint.origin`
/// 完全一致——一个 Worker 承担全部 endpoint。模块不能互相 import，
/// 靠 `FeedbackEndpointTests` 和 `OutboundHostsTests` 锁死。
public enum FeedbackEndpoint: Sendable {
    public static let origin = URL(string: "https://api.tollcat.app")!

    public static var feedbackURL: URL {
        origin.appending(path: "v1/feedback")
    }
}
