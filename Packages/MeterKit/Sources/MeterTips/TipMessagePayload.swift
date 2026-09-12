import Foundation

/// 打赏留言离开设备时只带这些字段。
///
/// JWS 这轮存而不验：Worker 还没做签名校验，有人可以伪造一条留言，
/// 但拿不到钱，最坏是垃圾留言。账单凭据和账单数据不在这个 payload 里，
/// 也永远不该加进来。
public struct TipMessagePayload: Hashable, Sendable, Encodable {
    public var transactionID: String
    public var jws: String
    public var productID: String
    public var displayPrice: String
    public var name: String?
    public var message: String?
    public var appVersion: String

    public init(
        transactionID: String,
        jws: String,
        productID: String,
        displayPrice: String,
        name: String? = nil,
        message: String? = nil,
        appVersion: String
    ) {
        self.transactionID = transactionID
        self.jws = jws
        self.productID = productID
        self.displayPrice = displayPrice
        self.name = TipFieldLimits.clampName(name)
        self.message = TipFieldLimits.clampMessage(message)
        self.appVersion = appVersion
    }
}
