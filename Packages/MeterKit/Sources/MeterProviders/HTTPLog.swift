import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(os)
import os
#endif

/// 开发构建才写。密钥不进日志。
enum HTTPLog {
    #if canImport(os) && DEBUG
    static let logger = Logger(subsystem: "com.zhechengqi.tollcat", category: "http")
    #endif

    static func request(
        _ request: URLRequest,
        status: Int?,
        bytes: Int?,
        error: Error?,
        elapsed: Duration
    ) {
        #if canImport(os) && DEBUG
        let method = request.httpMethod ?? "GET"
        let url = HTTPExchange.redactedURLString(request.url)
        let ms = elapsed / .milliseconds(1)
        var parts = ["\(method) \(url)", String(format: "%.0fms", ms)]
        if let status {
            parts.append("HTTP \(status)")
        }
        if let bytes {
            parts.append("\(bytes)B")
        }
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            parts.append("Authorization: ***")
        }
        if let error {
            parts.append(String(describing: error))
        }
        logger.info("\(parts.joined(separator: " "), privacy: .public)")
        #endif
    }
}
