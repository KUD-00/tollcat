import Foundation

public struct BalanceAlertModuleContent: Equatable, Sendable {
    public var items: [BalanceAlertItem]

    public init(items: [BalanceAlertItem]) {
        self.items = items
    }

    public var animationSignature: [Int] {
        items.map(\.daysRemaining)
    }
}
