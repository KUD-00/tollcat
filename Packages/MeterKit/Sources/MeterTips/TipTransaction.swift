import Foundation

public struct TipTransaction: Hashable, Sendable {
    public var id: String
    public var productID: String
    public var displayPrice: String
    public var jws: String
    public var purchasedAt: Date

    public init(
        id: String,
        productID: String,
        displayPrice: String,
        jws: String,
        purchasedAt: Date
    ) {
        self.id = id
        self.productID = productID
        self.displayPrice = displayPrice
        self.jws = jws
        self.purchasedAt = purchasedAt
    }
}
