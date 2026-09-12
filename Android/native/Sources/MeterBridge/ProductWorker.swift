import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MeterProviders

/// 匿名计数、反馈和打赏留言的出口。平台皮不许自己发 HTTP——URL 编在这里，
/// 走 `LiveHTTPTransport`，出站闸自动覆盖。
///
/// 打赏留言曾经是 Kotlin 自己 `HttpURLConnection` 发的：那道「POST 必须关掉
/// 跟随重定向」的闸只按文件名认人，新文件天然在闸外。三条都收进这里之后，
/// 那一端一行 HTTP 都没有了。
package enum ProductWorker {
    private static let usageURL = URL(string: "https://api.tollcat.app/v1/usage")!
    private static let feedbackURL = URL(string: "https://api.tollcat.app/v1/feedback")!
    private static let tipURL = URL(string: "https://api.tollcat.app/v1/tip")!

    package static func usageJson(payloadJSON: String) -> String {
        post(url: usageURL, body: payloadJSON, timeout: 10)
    }

    package static func feedbackJson(payloadJSON: String) -> String {
        post(url: feedbackURL, body: payloadJSON, timeout: 20)
    }

    /// 打赏留言。**账单凭据和账单数据不在这个 payload 里**（SPEC 12.5）。
    package static func tipJson(payloadJSON: String) -> String {
        post(url: tipURL, body: payloadJSON, timeout: 20)
    }

    private static func post(url: URL, body: String, timeout: TimeInterval) -> String {
        guard let data = body.data(using: .utf8) else {
            return JNIJSON.stringify(["ok": false, "error": "invalid utf-8"])
        }
        do {
            // URLRequest 在 corelibs-foundation 上不是 Sendable，不能被 @Sendable
            // 闭包捕获；在闭包里现造，只带出 Sendable 的状态码。
            let status: Int = try JNIAsync.run {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = data
                request.timeoutInterval = timeout
                let (_, response) = try await LiveHTTPTransport.make().send(request)
                return response.statusCode
            }
            if status == 429 {
                return JNIJSON.stringify(["ok": false, "rateLimited": true, "status": 429])
            }
            let ok = (200..<300).contains(status)
            return JNIJSON.stringify(["ok": ok, "status": status])
        } catch {
            return JNIJSON.stringify(["ok": false, "error": String(describing: error)])
        }
    }
}
