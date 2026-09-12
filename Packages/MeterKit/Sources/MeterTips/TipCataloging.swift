import Foundation

public protocol TipCataloging: Sendable {
    func loadProducts() async throws -> [TipOffering]
}
