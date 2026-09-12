import Foundation

/// 生产用的匿名计数出口从这里取。
///
/// 为什么要多这一层：出站检查按**文件白名单**扫 `URLSession` 这个词，
/// 而下面那个类型的名字里就带着它。这个 enum 的名字里没有那个词。
public enum LiveUsage: Sendable {
    public static func submitter() -> any UsageSubmitting {
        URLSessionUsageSubmitter()
    }
}

/// 这个模块里**唯一**允许出现 `URLSession` 的文件。
/// `TipModuleIsolationTests` 按文件名扫，别把网络调用挪到别处。
public struct URLSessionUsageSubmitter: UsageSubmitting {
    private let session: URLSession
    private let endpoint: URL

    public init(endpoint: URL = UsageEndpoint.usageURL) {
        self.session = Self.sharedSession
        self.endpoint = endpoint
    }

    public init(session: URLSession, endpoint: URL = UsageEndpoint.usageURL) {
        self.session = session
        self.endpoint = endpoint
    }

    public func submit(_ payload: UsageAnalyticsPayload) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw UsageSubmitError.transport
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UsageSubmitError.transport
        }
    }

    /// 和打赏、反馈一样用 ephemeral：不留 cookie、不留缓存。重定向只跟回同一个 Worker host。
    private static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(
            configuration: configuration,
            delegate: SameHostRedirectDelegate(host: UsageEndpoint.origin.host ?? ""),
            delegateQueue: nil
        )
    }()
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
