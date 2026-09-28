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
                    // updates 会推 App 的所有 StoreKit 交易。只认三档打赏；别的商品不 yield、
                    // 也不 finish，留给它自己的处理方交付。
                    guard TipProductID(rawValue: transaction.productID) != nil else { continue }
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
                    // 不在这里 finish：yield 只是入队，不代表已经记下。见 `finish(transactionID:)`。
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func finish(transactionID: String) async {
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result,
                  String(transaction.id) == transactionID
            else { continue }
            await transaction.finish()
            return
        }
    }

    private static func displayPrice(for productID: String) async -> String {
        let products = try? await Product.products(for: [productID])
        return products?.first?.displayPrice ?? ""
    }
}
