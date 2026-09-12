import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 传输层接缝。真实 provider 只通过它发请求；单测注入 `StubHTTPClient`。
public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
