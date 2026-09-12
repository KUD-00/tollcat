import Foundation

/// 留言的唯一出口。失败由调用方留在本地重试，不要把它做成购买失败。
public struct TipWorkerClient: TipMessageSubmitting {
    private let session: URLSession
    private let endpoint: URL

    public init(endpoint: URL = TipWorkerEndpoint.tipURL) {
        self.session = TipWorkerClient.sharedSession
        self.endpoint = endpoint
    }

    public init(session: URLSession, endpoint: URL = TipWorkerEndpoint.tipURL) {
        self.session = session
        self.endpoint = endpoint
    }

    public func submit(_ payload: TipMessagePayload) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TipMessageError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw TipMessageError.httpStatus(http.statusCode)
        }
    }

    private static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(
            configuration: configuration,
            delegate: SameHostRedirectDelegate(host: TipWorkerEndpoint.origin.host ?? ""),
            delegateQueue: nil
        )
    }()
}

/// 留言 POST 不能跟到 Worker origin 以外。
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
