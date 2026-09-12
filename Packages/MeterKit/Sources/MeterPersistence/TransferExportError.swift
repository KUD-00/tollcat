import Foundation

public enum TransferExportError: Error, Equatable, Sendable {
    case encodingFailed
    case keyDerivationFailed
    case sealingFailed
    case unreadableSubscription
    case writeFailed
}
