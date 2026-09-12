import Foundation
import StoreKit

public struct StoreKitTipCatalog: TipCataloging {
    public init() {}

    public func loadProducts() async throws -> [TipOffering] {
        let products = try await Product.products(for: TipProductID.allRawValues)
        return products
            .map { product in
                TipOffering(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice
                )
            }
            .sorted { lhs, rhs in
                (lhs.productID?.sortIndex ?? .max) < (rhs.productID?.sortIndex ?? .max)
            }
    }
}
