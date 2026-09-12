import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(os)
import os
#else
import Synchronization
#endif

/// 包一层真实 `HTTPClient`，记下每次往返。只给开发构建的测试连接和刷新日志用。
public final class InspectingHTTPClient: HTTPClient, Sendable {
    private let base: any HTTPClient
    private let limit: Int
    #if canImport(os)
    private let storage = OSAllocatedUnfairLock(initialState: [HTTPExchange]())
    #else
    private let storage = Mutex<[HTTPExchange]>([])
    #endif

    public init(wrapping base: any HTTPClient, limit: Int = 50) {
        self.base = base
        self.limit = max(1, limit)
    }

    public var exchanges: [HTTPExchange] {
        storage.withLock { $0 }
    }

    public func clear() {
        storage.withLock { $0 = [] }
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await base.send(request)
            append(.captured(request: request, data: data, response: response))
            return (data, response)
        } catch {
            append(.failed(request: request, error: error))
            throw error
        }
    }

    private func append(_ exchange: HTTPExchange) {
        storage.withLock { buffer in
            buffer.append(exchange)
            if buffer.count > limit {
                buffer.removeFirst(buffer.count - limit)
            }
        }
    }
}
