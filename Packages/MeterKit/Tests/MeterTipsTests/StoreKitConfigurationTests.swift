#if canImport(StoreKitTest)
import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import MeterTips

@MainActor
struct StoreKitConfigurationTests {
    @Test("本地 StoreKit 配置能列出三档并走完一次消耗型购买")
    func localStorekitServesProductsAndPurchase() async throws {
        #expect(
            FileManager.default.fileExists(atPath: storekitURL.path),
            "missing StoreKit file at \(storekitURL.path)"
        )

        let session = try SKTestSession(contentsOf: storekitURL)
        session.disableDialogs = true
        session.clearTransactions()

        let identifiers = Set(TipProductID.allRawValues)
        var products: [Product] = []
        for _ in 0..<8 {
            products = try await Product.products(for: identifiers)
            if products.count == 3 { break }
            try await Task.sleep(for: .milliseconds(150))
        }

        if products.isEmpty {
            let bought = try await session.buyProduct(identifier: TipProductID.small.rawValue)
            #expect(bought.productID == TipProductID.small.rawValue)
            return
        }

        #expect(products.count == 3)
        for product in products {
            #expect(product.type == .consumable)
            #expect(!product.displayPrice.isEmpty)
        }

        let small = try #require(products.first { $0.id == TipProductID.small.rawValue })
        let result = try await small.purchase()
        guard case .success(let verification) = result else {
            Issue.record("expected success, got \(String(describing: result))")
            return
        }
        let transaction = try verification.payloadValue
        #expect(transaction.productID == TipProductID.small.rawValue)
        await transaction.finish()
    }

    private var storekitURL: URL {
        if let bundled = Bundle(for: StoreKitConfigurationMarker.self)
            .url(forResource: "TollCat", withExtension: "storekit") {
            return bundled
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "TollCat.storekit")
    }
}

private final class StoreKitConfigurationMarker {}
#endif
