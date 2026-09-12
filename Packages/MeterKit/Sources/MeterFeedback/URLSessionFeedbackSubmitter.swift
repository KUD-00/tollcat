import Foundation

/// 生产用的反馈出口从这里取。
///
/// 为什么要多这一层：出站检查按**文件白名单**扫 `URLSession` 这个词，
/// 而下面那个类型的名字里就带着它——调用方写一次 `URLSessionFeedbackSubmitter()`
/// 就会让 `TipModuleIsolationTests` 变红。这个 enum 的名字里没有那个词，
/// 于是「网络代码只在这一个文件里」这条不变量能一直靠机器守着。
/// 和 `InboxClient.live()` 同一个理由、同一个位置。
public enum LiveFeedback: Sendable {
    public static func submitter() -> any FeedbackSubmitting {
        URLSessionFeedbackSubmitter()
    }
}

/// 这个模块里**唯一**允许出现 `URLSession` 的文件。
/// `TipModuleIsolationTests` 按文件名扫，别把网络调用挪到别处。
public struct URLSessionFeedbackSubmitter: FeedbackSubmitting {
    private let session: URLSession
    private let endpoint: URL

    public init(endpoint: URL = FeedbackEndpoint.feedbackURL) {
        self.session = Self.sharedSession
        self.endpoint = endpoint
    }

    public init(session: URLSession, endpoint: URL = FeedbackEndpoint.feedbackURL) {
        self.session = session
        self.endpoint = endpoint
    }

    public func submit(_ payload: FeedbackPayload) async throws {
        guard !payload.message.isEmpty else { throw FeedbackError.emptyMessage }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FeedbackError.transport
        }
        _ = data

        guard let http = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        if http.statusCode == 429 {
            throw FeedbackError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            throw FeedbackError.httpStatus(http.statusCode)
        }
    }

    /// 和打赏一样用 ephemeral：不留 cookie、不留缓存。重定向只跟回同一个 Worker host。
    private static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(
            configuration: configuration,
            delegate: SameHostRedirectDelegate(host: FeedbackEndpoint.origin.host ?? ""),
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
