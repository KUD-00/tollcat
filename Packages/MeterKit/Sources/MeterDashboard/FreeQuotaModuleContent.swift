import Foundation

public struct FreeQuotaModuleContent: Equatable, Sendable {
    public var items: [FreeQuotaItem]

    public init(items: [FreeQuotaItem]) {
        self.items = items
    }

    public var animationSignature: [Double] {
        items.map(\.usedRatio)
    }
}
