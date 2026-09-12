import Foundation
import MeterCore

/// `client_credentials` 换 access token。Atlas 服务账号和 Azure 服务主体都要先走这一步。
///
/// **不缓存 token。** 一次刷新多打一个请求，换来的是进程里不多存一份短期凭据、
/// 也不用再给它找一个持久化的家。刷新频率是分钟级，这笔交换不值得优化。
enum ProviderOAuth: Sendable {
    /// Basic 头里放 client id/secret（Atlas），或者把它们塞进表单（Azure）。两种都见过。
    static func clientCredentialsToken(
        url: URL,
        basic: (id: String, secret: String)?,
        form: [String: String],
        client: any HTTPClient,
        providerID: ProviderID
    ) async throws -> String {
        var headers = [
            "Content-Type": "application/x-www-form-urlencoded",
        ]
        if let basic {
            headers["Authorization"] = "Basic \(basicValue(id: basic.id, secret: basic.secret))"
        }
        let data = try await ProviderHTTP.post(
            url: url,
            headers: headers,
            body: Data(encode(form).utf8),
            client: client,
            providerID: providerID
        )
        let payload = try ProviderHTTP.decode(TokenResponse.self, from: data, providerID: providerID)
        guard let token = payload.access_token?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw ProviderError.unauthorized(providerID: providerID)
        }
        return token
    }

    static func basicValue(id: String, secret: String) -> String {
        Data("\(id):\(secret)".utf8).base64EncodedString()
    }

    /// 表单编码。key 排序固定，测试才能比对请求体。
    static func encode(_ form: [String: String]) -> String {
        form.keys.sorted()
            .map { "\(escape($0))=\(escape(form[$0] ?? ""))" }
            .joined(separator: "&")
    }

    /// `+` 在表单里是空格，`URLQueryAllowed` 不转义它，必须自己排除。
    private static func escape(_ raw: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
    }

    private struct TokenResponse: Decodable, Sendable {
        var access_token: String?
    }
}
