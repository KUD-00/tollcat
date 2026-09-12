import Foundation

enum DeviceTransferImportBanner: Equatable {
    case remainingAttempts(Int)
    case expired
    case invalidFile
    case invalidCode
    case locked(seconds: Int)
    case failed
    case success
    case unsupportedSchema
}
