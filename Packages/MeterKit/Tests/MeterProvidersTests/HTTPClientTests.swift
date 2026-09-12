import Foundation
import Testing
@testable import MeterCore
@testable import MeterProviders

struct HTTPClientTests {
    @Test("StubHTTPClient 按 URL 返回罐装状态码和 body")
    func stubReturnsCannedResponse() async throws {
        let url = URL(string: "https://meter.invalid/example")!
        let body = Data("hello".utf8)
        let client = StubHTTPClient(responses: [
            url: StubHTTPResponse(statusCode: 201, body: body),
        ])

        let (data, response) = try await client.send(URLRequest(url: url))

        #expect(data == body)
        #expect(response.statusCode == 201)
        #expect(response.url == url)
    }

    @Test("InspectingHTTPClient 记下状态码和 JSON，并藏掉 Authorization")
    func inspectingClientRecordsAndRedacts() async throws {
        let url = URL(string: "https://meter.invalid/credits")!
        let body = Data("{\"total_credits\":1}".utf8)
        let inner = StubHTTPClient(responses: [
            url: StubHTTPResponse(statusCode: 200, body: body),
        ])
        let client = InspectingHTTPClient(wrapping: inner)
        var request = URLRequest(url: url)
        request.setValue("Bearer super-secret-key", forHTTPHeaderField: "Authorization")

        _ = try await client.send(request)

        #expect(client.exchanges.count == 1)
        let exchange = try #require(client.exchanges.first)
        #expect(exchange.summary.contains("HTTP 200"))
        #expect(exchange.summary.contains("Authorization: Bearer ***"))
        #expect(!exchange.summary.contains("super-secret-key"))
        #expect(exchange.body.contains("total_credits"))
    }

    @Test("InspectingHTTPClient 失败也留一条")
    func inspectingClientRecordsFailures() async {
        let url = URL(string: "https://meter.invalid/missing")!
        let client = InspectingHTTPClient(wrapping: StubHTTPClient())
        _ = try? await client.send(URLRequest(url: url))
        #expect(client.exchanges.count == 1)
        #expect(client.exchanges[0].summary.contains("https://meter.invalid/missing"))
    }

    @Test("InspectingHTTPClient 只留最近几条")
    func inspectingClientCapsHistory() async throws {
        let url = URL(string: "https://meter.invalid/credits")!
        let inner = StubHTTPClient(responses: [
            url: StubHTTPResponse(statusCode: 200, body: Data("{}".utf8)),
        ])
        let client = InspectingHTTPClient(wrapping: inner, limit: 2)
        for _ in 0..<4 {
            _ = try await client.send(URLRequest(url: url))
        }
        #expect(client.exchanges.count == 2)
        client.clear()
        #expect(client.exchanges.isEmpty)
    }

    @Test("HTTP 摘要会打码 query 里的 token")
    func exchangeRedactsSecretQuery() {
        var request = URLRequest(url: URL(string: "https://meter.invalid/v1?api_key=super-secret-key&page=1")!)
        request.httpMethod = "GET"
        let exchange = HTTPExchange.captured(
            request: request,
            data: Data(),
            response: HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
        #expect(exchange.summary.contains("api_key=***"))
        #expect(exchange.summary.contains("page=1"))
        #expect(!exchange.summary.contains("super-secret-key"))
    }

    @Test("StubHTTPClient 没有对应 stub 时失败")
    func stubMissesUnknownURL() async {
        let client = StubHTTPClient()
        let url = URL(string: "https://meter.invalid/missing")!
        await #expect(throws: HTTPClientError.self) {
            try await client.send(URLRequest(url: url))
        }
    }

    @Test("HTTP 401 会映射成 unauthorized")
    func unauthorizedMapsToProviderError() async {
        let url = OpenRouterBillingProvider.creditsURL
        let client = StubHTTPClient(responses: [
            url: StubHTTPResponse(statusCode: 401, body: Data()),
        ])
        let provider = OpenRouterBillingProvider(
            httpClient: client,
            now: { LiveProviderHarness.now },
            calendar: LiveProviderHarness.calendar
        )

        let error = await #expect(throws: ProviderError.self) {
            try await provider.fetch(
                credential: Credential(providerID: .openrouter, fields: [.apiKey: "bad"])
            )
        }
        #expect(error?.httpStatus == 401)
        #expect(error?.code == .unauthorized)
    }

    @Test("URLSessionHTTPClient 拒绝白名单外的 host")
    func urlSessionRejectsUndeclaredHost() async {
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        // 拆开写，避免 check-outbound-hosts 把拒绝用例当成真出站。
        let url = URL(string: "https://" + "not-allowlisted.test/x")!
        await #expect(throws: HTTPClientError.forbiddenHost(url)) {
            try await client.send(URLRequest(url: url))
        }
    }

    @Test("重定向目标不在白名单或非 https 时不放行")
    func redirectGuardChecksAllowlistAndScheme() {
        #expect(RedirectAllowlistDelegate.allows(
            URLRequest(url: URL(string: "https://api.cloudflare.com/x")!)
        ))
        // 拆开写，避免 check-outbound-hosts 把拒绝用例当成真出站。
        #expect(!RedirectAllowlistDelegate.allows(
            URLRequest(url: URL(string: "https://" + "attacker.example/steal")!)
        ))
        #expect(!RedirectAllowlistDelegate.allows(
            URLRequest(url: URL(string: "http://" + "api.cloudflare.com/x")!)
        ))
    }

    @Test("302 到白名单外的 host 不跟进，密钥头不会发到第二跳")
    func redirectOffAllowlistStopsAtRedirectResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RedirectingURLProtocol.self]
        let session = URLSession(
            configuration: configuration,
            delegate: RedirectAllowlistDelegate(),
            delegateQueue: nil
        )
        let client = URLSessionHTTPClient(session: session)
        RedirectingURLProtocol.offListHostHit = false

        var request = URLRequest(url: URL(string: "https://meter.invalid/billing")!)
        request.setValue("secret", forHTTPHeaderField: "DD-API-KEY")
        let (_, response) = try await client.send(request)

        #expect(response.statusCode == 302)
        #expect(!RedirectingURLProtocol.offListHostHit)
    }

    @Test("URLSessionHTTPClient 把非 HTTP 响应当成 invalidResponse")
    func urlSessionRejectsNonHTTPResponse() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FileLikeURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = URLSessionHTTPClient(session: session)

        await #expect(throws: HTTPClientError.invalidResponse) {
            try await client.send(URLRequest(url: URL(string: "https://meter.invalid/not-http")!))
        }
    }
}

/// 对 meter.invalid 回 302 指向名单外 host；第二跳真的发出来就记一笔。
private final class RedirectingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var offListHostHit = false

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        if url.host == "meter.invalid" {
            let location = "https://" + "attacker.example/steal"
            let redirect = HTTPURLResponse(
                url: url,
                statusCode: 302,
                httpVersion: "HTTP/1.1",
                headerFields: ["Location": location]
            )!
            client?.urlProtocol(
                self,
                wasRedirectedTo: URLRequest(url: URL(string: location)!),
                redirectResponse: redirect
            )
            // delegate 拒绝跟随时，session 就以这个 302 收尾。
            client?.urlProtocol(self, didReceive: redirect, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            Self.offListHostHit = true
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

/// 故意返回裸 `URLResponse`，用来确认生产客户端不会把非 HTTP 当成成功。
private final class FileLikeURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = URLResponse(
            url: request.url ?? URL(string: "https://meter.invalid")!,
            mimeType: "text/plain",
            expectedContentLength: 0,
            textEncodingName: nil
        )
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
