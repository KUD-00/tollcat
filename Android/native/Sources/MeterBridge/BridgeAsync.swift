import Dispatch
import Foundation

/// 把 async 桥函数堵成同步出口。JNI 和 C ABI 都是同步调用约定，
/// 账单 `fetch` 必须在返回前结束。
package enum JNIAsync {
    package static func run<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) throws -> T {
        let box = ResultBox<T>()
        Task.detached {
            do {
                let value = try await body()
                box.finish(.success(value))
            } catch {
                box.finish(.failure(error))
            }
        }
        return try box.wait()
    }
}

private final class ResultBox<T: Sendable>: @unchecked Sendable {
    private let sem = DispatchSemaphore(value: 0)
    private var result: Result<T, Error>?

    func finish(_ result: Result<T, Error>) {
        self.result = result
        sem.signal()
    }

    func wait() throws -> T {
        sem.wait()
        return try result!.get()
    }
}
