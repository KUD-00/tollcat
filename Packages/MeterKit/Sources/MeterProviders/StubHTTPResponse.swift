import Foundation

/// 一条罐装 HTTP 响应。key 是请求 URL。
public struct StubHTTPResponse: Sendable, Equatable {
    public var statusCode: Int
    public var body: Data
    public var headerFields: [String: String]

    public init(
        statusCode: Int = 200,
        body: Data,
        headerFields: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.statusCode = statusCode
        self.body = body
        self.headerFields = headerFields
    }
}
