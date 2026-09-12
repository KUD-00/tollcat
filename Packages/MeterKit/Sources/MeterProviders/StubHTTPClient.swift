import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 单测用的罐装 HTTP 响应。App 走 `LiveHTTPTransport`，不走这里。
public struct StubHTTPClient: HTTPClient, Sendable {
    private let responses: [URL: StubHTTPResponse]

    public init(responses: [URL: StubHTTPResponse] = [:]) {
        self.responses = responses
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw HTTPClientError.invalidRequest
        }
        guard let canned = match(url) else {
            throw HTTPClientError.noStub(url)
        }
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: canned.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: canned.headerFields
        ) else {
            throw HTTPClientError.invalidResponse
        }
        return (canned.body, response)
    }

    private func match(_ url: URL) -> StubHTTPResponse? {
        if let exact = responses[url] {
            return exact
        }
        return responses.first { $0.key.path == url.path }?.value
    }
}
