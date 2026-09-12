import Foundation
import StoreKit

public struct StoreKitTipPurchaser: TipPurchasing {
    public init() {}

    public func purchase(productID: String) async -> TipPurchaseOutcome {
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                return .failed
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    let recorded = TipTransaction(
                        id: String(transaction.id),
                        productID: transaction.productID,
                        displayPrice: product.displayPrice,
                        jws: verification.jwsRepresentation,
                        purchasedAt: transaction.purchaseDate
                    )
                    await transaction.finish()
                    return .success(recorded)
                case .unverified:
                    return .failed
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch is CancellationError {
            return .cancelled
        } catch let error as StoreKitError {
            if case .userCancelled = error {
                return .cancelled
            }
            return .failed
        } catch {
            return .failed
        }
    }
}
