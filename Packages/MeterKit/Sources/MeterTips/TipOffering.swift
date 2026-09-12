import Foundation

/// 展示用的一档。价格只认 StoreKit 给的 `displayPrice`，这里不再折算。
public struct TipOffering: Identifiable, Hashable, Sendable {
    public var id: String
    public var displayName: String
    public var displayPrice: String

    public init(id: String, displayName: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
    }

    public var productID: TipProductID? {
        TipProductID(rawValue: id)
    }
}
