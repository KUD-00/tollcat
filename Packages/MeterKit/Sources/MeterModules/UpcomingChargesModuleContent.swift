import Foundation

public struct UpcomingChargesModuleContent: Equatable, Sendable {
    public var items: [UpcomingChargeItem]

    public init(items: [UpcomingChargeItem]) {
        self.items = items
    }

    public var animationSignature: [Double] {
        items.map { NSDecimalNumber(decimal: $0.amount.usd).doubleValue }
    }
}
