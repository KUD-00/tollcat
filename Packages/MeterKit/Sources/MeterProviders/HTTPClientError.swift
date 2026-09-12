import Foundation

/// `HTTPClient` 自己的失败。HTTP 状态码映射成 `ProviderError` 是 provider 的事。
public enum HTTPClientError: Error, Equatable, Sendable {
    case invalidRequest
    case invalidResponse
    case noStub(URL)
    /// 不在 `OutboundHosts` 白名单里，不许出网。
    case forbiddenHost(URL)
}
