import Foundation

/// 按配置缓存 formatter 实例。`DateFormatter`/`NumberFormatter` 的构造出了名的贵
/// （每次都要读 ICU 数据），而这些格式化函数在行构建器里一行一行地被调。
///
/// Formatter 本身不是线程安全的，所以**取用和格式化都在锁里做**——
/// iOS 侧基本只有主线程在用，锁没有竞争；Android JNI 侧调用线程不定，必须锁。
final class FormatterCache<Formatter>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Formatter] = [:]

    func use<Result>(key: String, make: () -> Formatter, _ body: (Formatter) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        if let cached = storage[key] {
            return body(cached)
        }
        let formatter = make()
        storage[key] = formatter
        return body(formatter)
    }
}
