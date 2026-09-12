import Foundation

public protocol TipMessageSubmitting: Sendable {
    func submit(_ payload: TipMessagePayload) async throws
}
