import Foundation
import MeterCore

public struct AnomalyModuleContent: Equatable, Sendable {
    public var items: [AnomalyItem]

    public init(items: [AnomalyItem]) {
        self.items = items
    }

    public var animationSignature: [Double] {
        items.map(\.changeRatio)
    }
}
