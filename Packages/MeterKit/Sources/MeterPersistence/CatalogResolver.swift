import Foundation
import MeterCore
import os

#if DEBUG
private let catalogLog = Logger(subsystem: "com.zhechengqi.tollcat", category: "catalog")
#endif

/// 目录的三层兜底：打包副本、上次拉成功的、网上最新。
///
/// `current()` 不碰网络，冷启动和 Widget 都走它。
/// `refresh()` 后台拉一次，失败静默，手里那份不动。
public final class CatalogResolver: CatalogSource, Sendable {
    private let memory = OSAllocatedUnfairLock<Catalog?>(initialState: nil)
    private let bundled: @Sendable () -> Catalog?
    private let cache: any CatalogCaching
    private let remote: (any CatalogSource)?

    public init(
        bundled: @escaping @Sendable () -> Catalog? = { BundledCatalogSource.loadBundled() },
        cache: any CatalogCaching,
        remote: (any CatalogSource)?
    ) {
        self.bundled = bundled
        self.cache = cache
        self.remote = remote
    }

    public static func live() -> CatalogResolver {
        CatalogResolver(
            cache: CatalogFileCache.appGroup(),
            remote: RemoteCatalogSource()
        )
    }

    /// 预览、测试、启动参数关掉远程时用。行为退回 M1：只读打包副本。
    public static func bundledOnly() -> CatalogResolver {
        CatalogResolver(cache: InMemoryCatalogCache(), remote: nil)
    }

    /// Widget 用：读打包副本和主 App 写过的缓存，结构上就拿不到远程源。
    /// 「Widget 不能自己调 API」靠这里的 `remote: nil` 成立，别顺手换成 live()。
    public static func readOnly() -> CatalogResolver {
        CatalogResolver(cache: CatalogFileCache.appGroup(), remote: nil)
    }

    public func current() -> Catalog {
        if let cached = memory.withLock({ $0 }) {
            return cached
        }
        let resolved = Self.resolve(bundled: bundled(), cached: cache.load())
        memory.withLock { $0 = resolved }
        return resolved
    }

    public func load() async throws -> Catalog {
        current()
    }

    /// 失败不抛。调用方不需要区分「没网」和「schema 太新」。
    @discardableResult
    public func refresh() async -> Catalog {
        let baseline = current()
        guard let remote else { return baseline }
        do {
            let fetched = try await remote.load()
            guard CatalogAcceptance.isUsable(fetched) else {
                #if DEBUG
                catalogLog.error("catalog rejected as unusable")
                #endif
                return baseline
            }
            if fetched.updatedAt >= (cache.load()?.updatedAt ?? .distantPast) {
                try cache.save(fetched)
            }
            let resolved = Self.resolve(bundled: bundled(), cached: cache.load())
            memory.withLock { $0 = resolved }
            #if DEBUG
            catalogLog.info("catalog ok updatedAt=\(resolved.updatedAt.timeIntervalSince1970, format: .fixed(precision: 0), privacy: .public)")
            #endif
            return resolved
        } catch {
            #if DEBUG
            catalogLog.error("catalog refresh fail \(String(describing: error), privacy: .public)")
            #endif
            return baseline
        }
    }

    /// 缓存比打包新才用缓存。一样新时用缓存——那是网上确认过的同一份。
    static func resolve(bundled: Catalog?, cached: Catalog?) -> Catalog {
        let usableCached = cached.flatMap { CatalogAcceptance.isUsable($0) ? $0 : nil }
        let usableBundled = bundled.flatMap { CatalogAcceptance.isUsable($0) ? $0 : nil }
        switch (usableBundled, usableCached) {
        case let (bundled?, cached?):
            return cached.updatedAt >= bundled.updatedAt ? cached : bundled
        case let (bundled?, nil):
            return bundled
        case let (nil, cached?):
            return cached
        case (nil, nil):
            return Catalog(
                schemaVersion: CatalogCodec.supportedSchemaVersion,
                updatedAt: .distantPast,
                guides: [:],
                plans: [],
                notices: []
            )
        }
    }
}
