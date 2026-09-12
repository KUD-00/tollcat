import Foundation

public enum TipMessageError: Error, Equatable, Sendable {
    case invalidResponse
    case httpStatus(Int)
}
