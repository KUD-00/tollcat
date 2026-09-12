import Foundation
import MeterCore
#if DEBUG
import os
#endif

/// 目录是公开 JSON，没有凭据。只认编译死的那个 host，跟到别处就丢掉。
public struct LiveCatalogTransport: CatalogTransport, Sendable {
    public static let maximumByteCount = 1_000_000

    private let session: URLSession
    private let allowedHost: String

    public init(allowedHost: String = CatalogEndpoint.origin.host ?? "") {
        self.session = Self.liveSession
        self.allowedHost = allowedHost
    }

    public init(session: URLSession, allowedHost: String = CatalogEndpoint.origin.host ?? "") {
        self.session = session
        self.allowedHost = allowedHost
    }

    /// ephemeral，重定向只跟回编译死的那个 host。目录没有凭据，但仍不能被拐走。
    static let liveSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(
            configuration: configuration,
            delegate: SameHostRedirectDelegate(host: CatalogEndpoint.origin.host ?? ""),
            delegateQueue: nil
        )
    }()

    public func get(_ url: URL) async throws -> (Data, URL) {
        guard url.host == allowedHost else { throw CatalogError.hostMismatch }
        let (data, response): (Data, URLResponse)
        #if DEBUG
        let started = ContinuousClock.now
        let catalogLog = Logger(subsystem: "com.zhechengqi.tollcat", category: "catalog")
        #endif
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            #if DEBUG
            catalogLog.error("catalog HTTP fail \(String(describing: error), privacy: .public)")
            #endif
            throw CatalogError.transportFailed
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            #if DEBUG
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            catalogLog.error("catalog HTTP \(status, privacy: .public)")
            #endif
            throw CatalogError.transportFailed
        }
        #if DEBUG
        let elapsedMs = Int((ContinuousClock.now - started) / .milliseconds(1))
        catalogLog.info("catalog HTTP 200 \(elapsedMs, privacy: .public)ms \(data.count, privacy: .public)B")
        #endif
        if let finalHost = response.url?.host, finalHost != allowedHost {
            throw CatalogError.hostMismatch
        }
        if data.count > Self.maximumByteCount {
            throw CatalogError.tooLarge
        }
        if data.isEmpty {
            throw CatalogError.emptyResponse
        }
        if let type = http.value(forHTTPHeaderField: "Content-Type"),
           !type.lowercased().contains("json") {
            throw CatalogError.invalidContentType
        }
        return (data, response.url ?? url)
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
