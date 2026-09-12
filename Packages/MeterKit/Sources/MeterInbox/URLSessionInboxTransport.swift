import Foundation
#if DEBUG
import os
#endif

/// 唯一真的发请求的地方。`TipModuleIsolationTests` 用白名单锁死了
/// `URLSession` 只能出现在少数几个文件里，这是其中之一。
public struct URLSessionInboxTransport: InboxTransport {
    private let session: URLSession

    public init() {
        self.session = Self.liveSession
    }

    public init(session: URLSession) {
        self.session = session
    }

    /// ephemeral：不留 cookie。read key 在 Authorization 头里，302 到别的 host 就不跟。
    static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(
            configuration: configuration,
            delegate: SameHostRedirectDelegate(host: InboxEndpoint.origin.host ?? ""),
            delegateQueue: nil
        )
    }()

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        #if DEBUG
        let started = ContinuousClock.now
        let inboxLog = Logger(subsystem: "com.zhechengqi.tollcat", category: "inbox")
        #endif
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                #if DEBUG
                inboxLog.error("inbox HTTP invalid response \(request.url?.host ?? "", privacy: .public)")
                #endif
                throw InboxError(code: .unreachable)
            }
            #if DEBUG
            let elapsedMs = Int((ContinuousClock.now - started) / .milliseconds(1))
            inboxLog.info(
                "inbox HTTP \(http.statusCode, privacy: .public) \(request.url?.path ?? "", privacy: .public) \(elapsedMs, privacy: .public)ms"
            )
            #endif
            return (data, http)
        } catch let error as InboxError {
            throw error
        } catch {
            #if DEBUG
            inboxLog.error("inbox HTTP fail \(String(describing: error), privacy: .public)")
            #endif
            throw error
        }
    }
}

extension InboxClient {
    /// 生产用的那一个。
    ///
    /// 放在这个文件而不是 `InboxClient.swift`：隔离测试规定 `URLSession` 这个词
    /// 只许出现在真正发请求的文件里。工厂跟着它的产物走，调用方写 `.live()` 就行。
    public static func live() -> InboxClient {
        InboxClient(transport: URLSessionInboxTransport())
    }
}

private final class SameHostRedirectDelegate: NSObject, URLSessionTaskDelegate {
    let host: String
    init(host: String) { self.host = host }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let url = request.url, url.scheme == "https", url.host == host else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }
}
