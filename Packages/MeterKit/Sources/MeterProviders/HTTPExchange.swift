import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 一次出站往返的可读摘要。给开发构建的「测试连接」看，不进生产 UI。
public struct HTTPExchange: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let summary: String
    public let body: String

    public init(id: UUID = UUID(), summary: String, body: String) {
        self.id = id
        self.summary = summary
        self.body = body
    }

    static func captured(
        request: URLRequest,
        data: Data,
        response: HTTPURLResponse
    ) -> HTTPExchange {
        HTTPExchange(
            summary: summary(request: request, status: response.statusCode, error: nil),
            body: prettyBody(data)
        )
    }

    static func failed(request: URLRequest, error: Error) -> HTTPExchange {
        HTTPExchange(
            summary: summary(request: request, status: nil, error: error),
            body: error.localizedDescription
        )
    }

    private static let maxBodyCharacters = 12_000

    /// query 里的 token / key 打成 `***`。摘要会进开发页和日志。
    static func redactedURLString(_ url: URL?) -> String {
        guard let url else { return "" }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        if components.user != nil { components.user = "***" }
        if components.password != nil { components.password = "***" }
        if let items = components.queryItems {
            components.queryItems = items.map { item in
                let name = item.name.lowercased()
                if name.contains("key") || name.contains("token")
                    || name.contains("secret") || name.contains("sign")
                {
                    return URLQueryItem(name: item.name, value: "***")
                }
                return item
            }
        }
        return components.string ?? url.absoluteString
    }

    private static func summary(request: URLRequest, status: Int?, error: Error?) -> String {
        let method = request.httpMethod ?? "GET"
        let url = redactedURLString(request.url)
        var lines = ["\(method) \(url)"]
        if let status {
            lines.append("HTTP \(status)")
        }
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            lines.append("Authorization: Bearer ***")
        }
        if let error {
            lines.append(String(describing: error))
        }
        return lines.joined(separator: "\n")
    }

    /// 正文里按字段名打码的键。Azure / Atlas / IBM 换 token 的响应体带
    /// `access_token`，摘要那层只打码 `Authorization` 和 query，正文原样进
    /// 开发页就能被复制走。
    ///
    /// 只认精确名与 `_token` / `_secret` 后缀，**不**用宽泛的 `contains("token")`：
    /// 用量响应里的 `total_tokens` / `prompt_tokens` 打码掉，这个抓包页也就没用了。
    private static let redactedFieldNames: Set<String> = [
        "secret", "password", "passwd", "authorization", "credential", "credentials",
        "apikey", "api_key", "secret_key", "secretkey", "private_key", "privatekey",
        "sas_token", "signature",
    ]

    /// 名字以 token 收尾就整棵打掉（access_token、authToken、裸 token、嵌套的
    /// `token: {id: …}` 都算），但 `tokens` 复数收尾的放过——用量响应里的
    /// total_tokens / prompt_tokens 打没了，这个抓包页就失去意义。
    ///
    /// 上一版只认精确名与 `_token` 后缀，于是 Fiskil / Scalingo / Openprovider /
    /// Soracom 的 `token`、Frank Energie 的 `authToken` / `refreshToken`、
    /// ConoHa / Rackspace 的 `access.token.id` 全部漏网。这不只是开发页的事：
    /// 反馈界面有个「附带这次测试的 HTTP 响应」开关，文案向用户保证密钥已打码，
    /// 打开后正文会 POST 到第一方 Worker，而 Worker 明确不该收到 provider 凭据。
    private static func isSecretName(_ name: String) -> Bool {
        if redactedFieldNames.contains(name) { return true }
        if name.hasSuffix("_secret") || name.hasSuffix("-secret") { return true }
        if name.hasSuffix("tokens") { return false }
        return name == "token" || name.hasSuffix("token")
    }

    static func redactedJSON(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (key, nested) in dictionary {
                // 整棵打掉：值可能是字符串，也可能是 {id: …} 这种嵌套信封。
                out[key] = isSecretName(key.lowercased()) ? "***" : redactedJSON(nested)
            }
            return out
        }
        if let array = value as? [Any] { return array.map(redactedJSON) }
        return value
    }

    private static func prettyBody(_ data: Data) -> String {
        if data.isEmpty { return "" }
        if let object = try? JSONSerialization.jsonObject(with: data),
           JSONSerialization.isValidJSONObject(object),
           let pretty = try? JSONSerialization.data(
            withJSONObject: redactedJSON(object),
            options: [.prettyPrinted, .sortedKeys]
           ),
           let text = String(data: pretty, encoding: .utf8)
        {
            return clipped(text)
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return clipped(text)
        }
        return "<\(data.count) bytes>"
    }

    private static func clipped(_ text: String) -> String {
        if text.count <= maxBodyCharacters { return text }
        return String(text.prefix(maxBodyCharacters)) + "\n…"
    }
}
