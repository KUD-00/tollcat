import Foundation

public enum TransferImportError: Error, Equatable, Sendable {
    case invalidFile
    case unsupportedVersion
    case unsupportedPayloadSchema
    case authenticationFailed
    case expired
    case weakKeyDerivation
    case persistenceFailed
}
