import Foundation

/// 信箱这条链路的失败。不带拼好的中文——文案在 MeterFeatures。
public struct InboxError: Error, Hashable, Sendable {
    public var code: Code
    public var httpStatus: Int?

    public enum Code: String, Hashable, Sendable {
        /// 读 key 无效或信箱已被删。要重新建一个。
        case unauthorized
        /// 网络没通，或者 Worker 挂了。已接入的其它家不受影响。
        case unreachable
        /// 服务端返回的东西解不出来。
        case malformedResponse
        case rateLimited
    }

    public init(code: Code, httpStatus: Int? = nil) {
        self.code = code
        self.httpStatus = httpStatus
    }

    static func fromHTTPStatus(_ status: Int) -> InboxError? {
        switch status {
        case 200..<300: nil
        case 401, 403: InboxError(code: .unauthorized, httpStatus: status)
        case 429: InboxError(code: .rateLimited, httpStatus: status)
        default: InboxError(code: .unreachable, httpStatus: status)
        }
    }
}
