import Foundation

/// 罐装应答。给模拟器截图和 UI 验收用，**一个字节都不出网**。
///
/// 和 `MeterProviders.StubHTTPClient` 一个用意：验收这几屏不该在生产库里
/// 留下真信箱。只在带 `-stub-inbox` 启动参数时才会被装上。
public struct StubInboxTransport: InboxTransport {
    public init() {}

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let path = request.url?.path() ?? ""
        let method = request.httpMethod ?? "GET"
        let (status, json) = Self.canned(path: path, method: method)
        let response = HTTPURLResponse(
            url: request.url ?? InboxEndpoint.origin,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(json.utf8), response)
    }

    static func canned(path: String, method: String) -> (Int, String) {
        switch (method, path) {
        case ("POST", "/v1/inbox"):
            return (201, """
            {"mailbox":"mb_stub_0123456789abcdef",
             "readKey":"tollr_STUB_READ_KEY",
             "ingestKey":"tolli_STUB_INGEST_KEY_9f3a2c",
             "ingestKeyID":"key_stub_1"}
            """)
        case ("POST", "/v1/inbox/ingest-keys"):
            return (201, """
            {"ingestKey":"tolli_STUB_NEW_KEY_77b1","ingestKeyID":"key_stub_2"}
            """)
        case ("GET", "/v1/inbox/ingest-keys"):
            return (200, """
            {"keys":[
              {"id":"key_stub_1","label":"Render 抓取",
               "createdAt":"2026-08-01T09:00:00Z","lastUsedAt":"2026-08-17T02:00:00Z"},
              {"id":"key_stub_2","label":"Expo 抓取",
               "createdAt":"2026-08-12T09:00:00Z","lastUsedAt":null}
            ]}
            """)
        case ("GET", "/v1/readings"):
            return (200, """
            {"readings":[
              {"provider":"render","ingestKeyID":"key_stub_1","periodStart":"2026-08-01",
               "currentSpendUSD":"12.34","reportedAt":"2026-08-17T02:00:00Z"}
            ]}
            """)
        default:
            return (200, #"{"ok":true}"#)
        }
    }
}

extension InboxClient {
    /// 截图 / 验收用的那一个。不出网。
    public static func stub() -> InboxClient {
        InboxClient(transport: StubInboxTransport())
    }
}
