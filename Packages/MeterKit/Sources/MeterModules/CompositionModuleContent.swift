import Foundation
import MeterCore

public struct CompositionModuleContent: Equatable, Sendable {
    public var segments: [CompositionSegment]
    public var totalText: String
    public var spokenTotal: String
    public var destination: AccountID?

    public init(
        segments: [CompositionSegment],
        totalText: String,
        spokenTotal: String,
        destination: AccountID? = nil
    ) {
        self.segments = segments
        self.totalText = totalText
        self.spokenTotal = spokenTotal
        self.destination = destination
    }

    public var animationSignature: [Double] {
        segments.map(\.fraction)
    }
}
