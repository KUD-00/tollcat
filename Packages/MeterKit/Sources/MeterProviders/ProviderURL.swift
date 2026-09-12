import Foundation

/// 手搭 provider API URL 的唯一入口。host / path 都是写死常量，拼不出来是编程错误。
enum ProviderURL: Sendable {
    static func https(
        host: String,
        path: String,
        query: [URLQueryItem] = []
    ) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
        }
        return components.url!
    }
}
