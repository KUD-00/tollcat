import Foundation

struct FileHandleStream: TextOutputStream {
    var handle: FileHandle

    mutating func write(_ string: String) {
        if let data = string.data(using: .utf8), !data.isEmpty {
            handle.write(data)
        }
    }
}
