import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

/// 记录层的日表按日历分量落盘，读写都要一本日历。测试统一用 UTC 公历。
private let recordCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    return c
}()

@MainActor
struct ExchangeRateCatalogTests {
    @Test("打包目录带汇率，人民币在里面——DeepSeek 和 Moonshot (China) 的国内户靠它")
    func bundledCatalogCarriesRates() async throws {
        let catalog = try await BundledCatalogSource().load()
        #expect(catalog.exchangeRates.supports("CNY"))
        #expect(catalog.exchangeRates.supports("EUR"))
        #expect(catalog.exchangeRates.supports("JPY"))
        // 美元永远认，不需要写进表里。
        #expect(catalog.exchangeRates.supports("USD"))
        #expect(catalog.exchangeRates.supports(nil))
        // 没收录的币种不许猜。
        #expect(!catalog.exchangeRates.supports("XYZ"))
    }

    @Test("同步读那条路和 async 读的是同一份")
    func syncLoadMatchesAsync() async throws {
        let asyncCatalog = try await BundledCatalogSource().load()
        let syncCatalog = try #require(BundledCatalogSource.loadBundled())
        #expect(syncCatalog.exchangeRates == asyncCatalog.exchangeRates)
        #expect(syncCatalog.guides.count == asyncCatalog.guides.count)
    }

    @Test("汇率过十进制字符串，不过 Double")
    func ratesRoundTripAsDecimalStrings() throws {
        let json = """
        {
          "schemaVersion": 1,
          "updatedAt": "2026-08-17T00:00:00Z",
          "exchangeRates": { "CNY": "0.1404", "JPY": "0.00655" }
        }
        """
        let catalog = try CatalogCodec.decode(Data(json.utf8))
        let cny = try #require(catalog.exchangeRates.toUSD(1, from: "CNY"))
        #expect(cny.usdPerUnit == Decimal(string: "0.1404"))
        let jpy = try #require(catalog.exchangeRates.toUSD(1, from: "jpy"))
        #expect(jpy.usdPerUnit == Decimal(string: "0.00655"))

        // 编回去仍然是字符串，分位不丢。
        let reencoded = try CatalogCodec.encode(catalog)
        let text = try #require(String(data: reencoded, encoding: .utf8))
        #expect(text.contains("\"0.1404\""))
    }

    @Test("老目录没有 exchangeRates 也能解，解出来只认美元")
    func legacyCatalogWithoutRates() throws {
        let json = """
        { "schemaVersion": 1, "updatedAt": "2026-08-17T00:00:00Z" }
        """
        let catalog = try CatalogCodec.decode(Data(json.utf8))
        #expect(catalog.exchangeRates == .usdOnly)
        #expect(catalog.exchangeRates.supports("USD"))
        #expect(!catalog.exchangeRates.supports("CNY"))
    }

    @Test("换算说明跟着快照落库，重启后不会退回「没换过币」")
    func conversionSurvivesPersistence() throws {
        let snapshot = Snapshot(
            providerID: .deepseek,
            accountID: AccountID.fixture(for: .deepseek),
            kind: .prepaid,
            fetchedAt: Date(timeIntervalSince1970: 1_787_000_000),
            periodStart: Date(timeIntervalSince1970: 1_785_542_400),
            periodEnd: Date(timeIntervalSince1970: 1_788_220_799),
            balanceUSD: Money(usd: Decimal(string: "16.85")!),
            converted: ConvertedAmount(
                currency: "CNY",
                amount: 120,
                usdPerUnit: Decimal(string: "0.1404")!,
                usd: Decimal(string: "16.85")!
            )
        )

        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(try SnapshotRecord(domain: snapshot, calendar: recordCalendar))
        try context.save()

        let stored = try context.fetch(FetchDescriptor<SnapshotRecord>())
        #expect(stored[0].convertedCurrency == "CNY")
        let restored = try stored[0].toDomain(calendar: recordCalendar)
        #expect(restored.isCurrencyConverted)
        #expect(restored.converted?.amount == 120)
        #expect(restored.converted?.usdPerUnit == Decimal(string: "0.1404"))
    }

}
