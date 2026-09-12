import Foundation

enum TransferEnvelope: Sendable {
    static func split(_ data: Data) throws -> (header: TransferFileHeader, ciphertext: Data, tag: Data) {
        let headerSize = TransferFileFormat.headerByteCount
        let tagSize = TransferFileFormat.tagByteCount
        guard data.count >= headerSize + tagSize else {
            throw TransferImportError.invalidFile
        }
        let header = try TransferFileHeader.decode(Data(data.prefix(headerSize)))
        let body = data.dropFirst(headerSize)
        let ciphertext = Data(body.dropLast(tagSize))
        let tag = Data(body.suffix(tagSize))
        return (header, ciphertext, tag)
    }
}
