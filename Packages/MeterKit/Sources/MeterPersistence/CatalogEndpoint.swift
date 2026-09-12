import Foundation

/// 在线目录的地址。编译在这里，不进 catalog 正文、不远程下发。
///
/// origin 必须和打赏 / 信箱 / 反馈 / 匿名计数那几份一模一样。模块不能互相
/// import，靠 `CatalogEndpointTests` 和源码闸锁死。
public enum CatalogEndpoint: Sendable {
    public static let origin = URL(string: "https://api.tollcat.app")!

    public static var catalogURL: URL {
        origin.appending(path: "v1/catalog")
    }
}
