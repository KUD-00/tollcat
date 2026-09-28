import Foundation

/// `%@` / `%lld` / `%d`（含 `%1$@` 位置式）按顺序或位置换成实参，`%%` 还原成 `%`。
/// 和 Apple 那边 `String(format:)` 对这几种写法的结果一致；别的转换符原样放回。
public enum PortableFormat {
    public static func render(_ pattern: String, _ arguments: [PortableText.Argument]) -> String {
        let values = arguments.map(\.rendered)
        var result = ""
        var next = 0
        var index = pattern.startIndex
        while index < pattern.endIndex {
            guard pattern[index] == "%" else {
                result.append(pattern[index])
                index = pattern.index(after: index)
                continue
            }
            var cursor = pattern.index(after: index)
            if cursor < pattern.endIndex, pattern[cursor] == "%" {
                result.append("%")
                index = pattern.index(after: cursor)
                continue
            }
            var position: Int?
            var digits = ""
            while cursor < pattern.endIndex, pattern[cursor].isNumber {
                digits.append(pattern[cursor])
                cursor = pattern.index(after: cursor)
            }
            if !digits.isEmpty, cursor < pattern.endIndex, pattern[cursor] == "$" {
                position = Int(digits)
                cursor = pattern.index(after: cursor)
            } else if !digits.isEmpty {
                result.append("%" + digits)
                index = cursor
                continue
            }
            let rest = pattern[cursor...]
            let consumed: Int
            if rest.hasPrefix("@") { consumed = 1 }
            else if rest.hasPrefix("lld") { consumed = 3 }
            else if rest.hasPrefix("ld") { consumed = 2 }
            else if rest.hasPrefix("d") { consumed = 1 }
            else { consumed = 0 }
            guard consumed > 0 else {
                result.append(pattern[index])
                index = pattern.index(after: index)
                continue
            }
            let argumentIndex = (position ?? (next + 1)) - 1
            if position == nil { next += 1 }
            result.append(values.indices.contains(argumentIndex) ? values[argumentIndex] : "")
            index = pattern.index(cursor, offsetBy: consumed)
        }
        return result
    }
}
