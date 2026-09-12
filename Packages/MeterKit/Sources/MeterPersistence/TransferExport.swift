import Foundation
import MeterCore

public struct TransferExport: Sendable {
    public let code: TransferCode
    public let fileBytes: Data
    public let notAfter: Date

    public init(code: TransferCode, fileBytes: Data, notAfter: Date) {
        self.code = code
        self.fileBytes = fileBytes
        self.notAfter = notAfter
    }
}
