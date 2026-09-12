import Foundation

public protocol TipPurchasing: Sendable {
    func purchase(productID: String) async -> TipPurchaseOutcome
}
