import Foundation
import StoreKit

/// 家长批准或进程中断后补到的已验证交易。消耗型不做恢复购买，只处理 `updates`。
public struct StoreKitTipTransactionListener: TipTransactionListening {
    public init() {}

    public func updates() -> AsyncStream<TipTransaction> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    guard case .verified(let transaction) = update else { continue }
                    let displayPrice = await Self.displayPrice(for: transaction.productID)
                    continuation.yield(
                        TipTransaction(
                            id: String(transaction.id),
                            productID: transaction.productID,
                            displayPrice: displayPrice,
                            jws: update.jwsRepresentation,
                            purchasedAt: transaction.purchaseDate
                        )
                    )
                    await transaction.finish()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func displayPrice(for productID: String) async -> String {
        let products = try? await Product.products(for: [productID])
        return products?.first?.displayPrice ?? ""
    }
}
