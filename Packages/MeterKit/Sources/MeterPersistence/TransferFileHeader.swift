import Foundation

struct TransferFileHeader: Equatable, Sendable {
    var version: UInt8
    var salt: Data
    var iterations: UInt32
    var nonce: Data
    var notAfter: UInt64

    func encoded() -> Data {
        var data = Data()
        data.reserveCapacity(TransferFileFormat.headerByteCount)
        data.append(TransferFileFormat.magic)
        data.append(version)
        data.append(salt)
        appendUInt32BE(iterations, to: &data)
        data.append(nonce)
        appendUInt64BE(notAfter, to: &data)
        return data
    }

    static func decode(_ data: Data) throws -> TransferFileHeader {
        guard data.count == TransferFileFormat.headerByteCount else {
            throw TransferImportError.invalidFile
        }
        guard data.prefix(TransferFileFormat.magicByteCount) == TransferFileFormat.magic else {
            throw TransferImportError.invalidFile
        }
        let version = data[TransferFileFormat.versionOffset]
        let salt = Data(data[TransferFileFormat.saltOffset ..< TransferFileFormat.iterationsOffset])
        let iterations = readUInt32BE(data, offset: TransferFileFormat.iterationsOffset)
        let nonce = Data(data[TransferFileFormat.nonceOffset ..< TransferFileFormat.notAfterOffset])
        let notAfter = readUInt64BE(data, offset: TransferFileFormat.notAfterOffset)
        guard salt.count == TransferFileFormat.saltByteCount,
              nonce.count == TransferFileFormat.nonceByteCount else {
            throw TransferImportError.invalidFile
        }
        return TransferFileHeader(
            version: version,
            salt: salt,
            iterations: iterations,
            nonce: nonce,
            notAfter: notAfter
        )
    }
}

private func appendUInt32BE(_ value: UInt32, to data: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
}

private func appendUInt64BE(_ value: UInt64, to data: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
}

private func readUInt32BE(_ data: Data, offset: Int) -> UInt32 {
    var value: UInt32 = 0
    withUnsafeMutableBytes(of: &value) { destination in
        _ = data.copyBytes(to: destination, from: offset ..< (offset + 4))
    }
    return UInt32(bigEndian: value)
}

private func readUInt64BE(_ data: Data, offset: Int) -> UInt64 {
    var value: UInt64 = 0
    withUnsafeMutableBytes(of: &value) { destination in
        _ = data.copyBytes(to: destination, from: offset ..< (offset + 8))
    }
    return UInt64(bigEndian: value)
}
