import Foundation

public enum CredentialStoreError: Error, Equatable, Sendable {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
}
