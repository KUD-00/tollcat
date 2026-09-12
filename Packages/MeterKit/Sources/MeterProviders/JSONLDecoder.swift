import Foundation

/// FOCUS / Vercel 这类 JSONL：一行一个对象。`//` 开头的行是 fixture 注释。
enum JSONLDecoder: Sendable {
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> [T] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "JSONL is not UTF-8")
            )
        }
        let decoder = JSONDecoder()
        var items: [T] = []
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("//") { continue }
            let lineData = Data(line.utf8)
            items.append(try decoder.decode(type, from: lineData))
        }
        return items
    }
}
