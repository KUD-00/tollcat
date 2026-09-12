import Foundation
import Testing
import MeterCore
@testable import MeterPersistence

struct CatalogResolverTests {
    @Test("没有缓存时用打包那份")
    func bundledWhenCacheEmpty() {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: InMemoryCatalogCache(),
            remote: nil
        )
        let current = resolver.current()
        #expect(current.updatedAt == bundled.updatedAt)
        #expect(current.exchangeRates.supports("CNY"))
    }

    @Test("缓存比打包新就用缓存")
    func newerCacheWins() {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let cached = makeCatalog(updatedAt: date(2026, 8, 18), cny: "0.15")
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: InMemoryCatalogCache(cached),
            remote: nil
        )
        #expect(resolver.current().updatedAt == cached.updatedAt)
        let unit = resolver.current().exchangeRates.toUSD(1, from: "CNY")?.usdPerUnit
        #expect(unit == Decimal(string: "0.15"))
    }

    @Test("缓存比打包旧就丢掉，用打包")
    func olderCacheLoses() {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 18), cny: "0.14")
        let cached = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.10")
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: InMemoryCatalogCache(cached),
            remote: nil
        )
        #expect(resolver.current().updatedAt == bundled.updatedAt)
    }

    @Test("远程拉成功就写入缓存，current 跟着换")
    func refreshSavesNewerRemote() async {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let remote = makeCatalog(updatedAt: date(2026, 8, 18), cny: "0.16")
        let cache = InMemoryCatalogCache()
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: cache,
            remote: StaticCatalogSource(remote)
        )
        let result = await resolver.refresh()
        #expect(result.updatedAt == remote.updatedAt)
        #expect(cache.load()?.updatedAt == remote.updatedAt)
        #expect(resolver.current().updatedAt == remote.updatedAt)
    }

    @Test("远程失败静默，手里那份不动")
    func refreshFailureKeepsBaseline() async {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let cache = InMemoryCatalogCache()
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: cache,
            remote: FailingCatalogSource()
        )
        let result = await resolver.refresh()
        #expect(result.updatedAt == bundled.updatedAt)
        #expect(cache.load() == nil)
    }

    @Test("远程 schema 太新整份丢掉")
    func unsupportedRemoteIsIgnored() async throws {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let cache = InMemoryCatalogCache()
        let payload = """
        { "schemaVersion": 99, "updatedAt": "2026-08-18T00:00:00Z" }
        """.data(using: .utf8)!
        let remote = RemoteCatalogSource(transport: StubCatalogTransport(data: payload))
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: cache,
            remote: remote
        )
        let result = await resolver.refresh()
        #expect(result.updatedAt == bundled.updatedAt)
        #expect(cache.load() == nil)
    }

    @Test("远程比缓存旧就不覆盖")
    func olderRemoteDoesNotClobberCache() async {
        let bundled = makeCatalog(updatedAt: date(2026, 8, 1), cny: "0.14")
        let cached = makeCatalog(updatedAt: date(2026, 8, 18), cny: "0.15")
        let remote = makeCatalog(updatedAt: date(2026, 8, 10), cny: "0.11")
        let cache = InMemoryCatalogCache(cached)
        let resolver = CatalogResolver(
            bundled: { bundled },
            cache: cache,
            remote: StaticCatalogSource(remote)
        )
        let result = await resolver.refresh()
        #expect(cache.load()?.updatedAt == cached.updatedAt)
        #expect(result.updatedAt == cached.updatedAt)
    }

    @Test("磁盘缓存往返后还认得人民币")
    func fileCacheRoundTrips() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "catalog-cache-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let cache = CatalogFileCache(fileURL: url)
        let catalog = makeCatalog(updatedAt: date(2026, 8, 18), cny: "0.1404")
        try cache.save(catalog)
        let loaded = try #require(cache.load())
        #expect(loaded.updatedAt == catalog.updatedAt)
        #expect(loaded.exchangeRates.toUSD(1, from: "CNY")?.usdPerUnit == Decimal(string: "0.1404"))
    }

    @Test("schema 太新的缓存当没有")
    func fileCacheRejectsUnsupportedSchema() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "catalog-cache-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let payload = """
        { "schemaVersion": 99, "updatedAt": "2026-08-18T00:00:00Z" }
        """
        try Data(payload.utf8).write(to: url)
        #expect(CatalogFileCache(fileURL: url).load() == nil)
    }

    private func makeCatalog(updatedAt: Date, cny: String) -> Catalog {
        Catalog(
            schemaVersion: CatalogCodec.supportedSchemaVersion,
            updatedAt: updatedAt,
            guides: [:],
            plans: [],
            notices: [],
            exchangeRates: ExchangeRates(usdPerUnit: ["CNY": Decimal(string: cny)!])
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
    }
}

private struct StaticCatalogSource: CatalogSource {
    var catalog: Catalog
    init(_ catalog: Catalog) { self.catalog = catalog }
    func load() async throws -> Catalog { catalog }
}

private struct FailingCatalogSource: CatalogSource {
    func load() async throws -> Catalog {
        throw CatalogError.transportFailed
    }
}
