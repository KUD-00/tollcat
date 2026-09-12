import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 生产用的传输实现。不在 `OutboundHosts` 里的 host 直接拒绝。
///
/// 白名单查两次：发请求前查原始 URL，跟随重定向前再查目标 URL——
/// 厂商或前置 CDN 302 到名单外主机时，DD-API-KEY / xi-api-key 这类
/// 不会被系统剥掉的自定义密钥头才不会跟着新请求发出去。
public struct URLSessionHTTPClient: HTTPClient, Sendable {
    private let session: URLSession

    public init() {
        self.session = URLSession(
            configuration: .ephemeral,
            delegate: RedirectAllowlistDelegate(),
            delegateQueue: nil
        )
    }

    public init(session: URLSession) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw HTTPClientError.invalidRequest
        }
        guard OutboundHosts.contains(url) else {
            throw HTTPClientError.forbiddenHost(url)
        }
        #if DEBUG
        let started = ContinuousClock.now
        #endif
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                #if DEBUG
                HTTPLog.request(
                    request,
                    status: nil,
                    bytes: data.count,
                    error: HTTPClientError.invalidResponse,
                    elapsed: ContinuousClock.now - started
                )
                #endif
                throw HTTPClientError.invalidResponse
            }
            #if DEBUG
            HTTPLog.request(
                request,
                status: http.statusCode,
                bytes: data.count,
                error: nil,
                elapsed: ContinuousClock.now - started
            )
            #endif
            return (data, http)
        } catch let error as HTTPClientError {
            throw error
        } catch {
            #if DEBUG
            HTTPLog.request(
                request,
                status: nil,
                bytes: nil,
                error: error,
                elapsed: ContinuousClock.now - started
            )
            #endif
            throw error
        }
    }
}

/// 重定向的目标也要过 `OutboundHosts`：不是 https 或不在名单里就不跟，
/// 请求停在 3xx 上，调用方按非 2xx 失败处理。
///
/// 名单里放行还不够。白名单是**整段相等**匹配，`github.com`、`api.openai.com`
/// 这些都在里面，所以「跳到名单内另一个 host」照样是把密钥送去别人家。系统只在
/// 跨 host 时剥 `Authorization`，`DD-API-KEY` / `xi-api-key` / `Fastly-Key`
/// 这类自定义头它不认，会原样跟过去。因此跨 host 时按白名单反过来做：只保留
/// 一小撮公认无害的头，其余全部丢掉。
final class RedirectAllowlistDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(Self.redirect(request, from: task.originalRequest?.url))
    }

    /// 跨 host 才会碰到的、公认不带凭据的头。其余一律不带过去。
    static let carriedAcrossHosts: Set<String> = [
        "accept", "accept-encoding", "accept-language", "content-type", "user-agent",
    ]

    static func redirect(_ request: URLRequest, from originalURL: URL?) -> URLRequest? {
        guard let url = request.url, allows(request) else { return nil }
        guard let host = url.host else { return nil }
        // 同 host 跳转（常见的 /a → /a/ 之类）原样跟随。
        if let originalHost = originalURL?.host, originalHost == host { return request }
        var stripped = request
        let carried = request.allHTTPHeaderFields ?? [:]
        for field in carried.keys where !carriedAcrossHosts.contains(field.lowercased()) {
            stripped.setValue(nil, forHTTPHeaderField: field)
        }
        return stripped
    }

    static func allows(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        // contains 自己已经要求 https，这里留着是为了读代码时一眼看见这条约束。
        return url.scheme == "https" && OutboundHosts.contains(url)
    }
}

/// 组装层拿真传输的入口。名字里不能带 Session，否则隔离测试会误伤调用方。
public enum LiveHTTPTransport: Sendable {
    public static func make() -> any HTTPClient {
        URLSessionHTTPClient()
    }
}
