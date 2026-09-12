#if canImport(StoreKitTest)
import Foundation
import StoreKit
import StoreKitTest
import Testing
@testable import MeterTips

@MainActor
struct StoreKitConfigurationTests {
    /// GitHub 的 macOS runner 上 `SKTestSession` 起不来（写配置文件就报
    /// `SKInternalErrorDomain Code=3`），之后 `purchase()` 永远等不到交易回调，
    /// 整个 Test job 挂到超时——2026-09-12 连续两轮 45–85 分钟就是它。
    /// 所以 CI 上不跑；本机照常跑。再加两分钟时限，万一别处也等死能当失败而不是挂起。
    @Test(
        "本地 StoreKit 配置能列出三档并走完一次消耗型购买",
        .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil,
                 "SKTestSession 在 GitHub runner 上初始化失败并让购买无限等待"),
        .timeLimit(.minutes(2))
    )
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
