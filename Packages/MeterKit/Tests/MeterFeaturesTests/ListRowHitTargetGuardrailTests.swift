import Foundation
import Testing

/// `.buttonStyle(.plain)` 在 List 里只点得到字。有 Spacer / 行组件 / 撑满宽
/// 的按钮必须在 label 上铺 `meterListRowHitTarget()`。
///
/// 提交闸 `scripts/check-source-invariants.py` 扫同一套判据。改了两边一起改。
struct ListRowHitTargetGuardrailTests {
    private static let rowShape = try! NSRegularExpression(
        pattern: #"\bSpacer\b|\bLabeledContent\b|\bProviderRow\b|\bManualSubscriptionRow\b|\bCompositionModuleView\b|chevron\.right|\browContent\b"#
    )
    private static let expanded = try! NSRegularExpression(
        pattern: #"maxWidth:\s*\.infinity"#
    )
    private static let control = try! NSRegularExpression(
        pattern: #"\b(?:Button|ShareLink)\b"#
    )
    private static let plain = ".buttonStyle(.plain)"

    @Test("plain 列表行都铺了整行热区")
    func plainListRowsExpandTheHitTarget() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources"]
        ) {
            if file.lastPathComponent == "ListRowHitTarget.swift" { continue }
            offenders.append(contentsOf: try Self.offenders(in: file, repoRoot: repoRoot))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    private static func offenders(in file: URL, repoRoot: URL) throws -> [String] {
        let original = try String(contentsOf: file, encoding: .utf8)
        let masked = maskCommentsAndStrings(original)
        var hits: [String] = []
        var search = masked.startIndex
        while let range = masked.range(of: plain, range: search..<masked.endIndex) {
            let prefix = String(masked[masked.startIndex..<range.lowerBound])
            guard let start = lastControlStart(in: prefix) else {
                search = range.upperBound
                continue
            }
            let construct = String(prefix.dropFirst(start))
            let hasHit = construct.contains("meterListRowHitTarget(")
            let looksLikeRow = rowShape.firstMatch(
                in: construct,
                range: NSRange(construct.startIndex..., in: construct)
            ) != nil
            let isExpanded = expanded.firstMatch(
                in: construct,
                range: NSRange(construct.startIndex..., in: construct)
            ) != nil
            let line = masked[masked.startIndex..<range.lowerBound]
                .filter { $0 == "\n" }.count + 1
            let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
            if looksLikeRow && !hasHit {
                hits.append("\(relative):\(line) `.plain` 列表行没有 meterListRowHitTarget()")
            } else if isExpanded && !hasHit && !construct.contains("contentShape(Rectangle())") {
                hits.append("\(relative):\(line) `.plain` 按钮撑满了宽却没铺热区")
            }
            search = range.upperBound
        }
        return hits
    }

    private static func lastControlStart(in prefix: String) -> Int? {
        let ns = prefix as NSString
        let matches = control.matches(
            in: prefix,
            range: NSRange(location: 0, length: ns.length)
        )
        return matches.last.map(\.range.location)
    }

    private static func maskCommentsAndStrings(_ text: String) -> String {
        var out = ""
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            let nxt = i + 1 < chars.count ? chars[i + 1] : "\0"
            if ch == "/" && nxt == "/" {
                while i < chars.count && chars[i] != "\n" {
                    out.append(" ")
                    i += 1
                }
                continue
            }
            if ch == "/" && nxt == "*" {
                out.append("  ")
                i += 2
                while i < chars.count {
                    if chars[i] == "*" && i + 1 < chars.count && chars[i + 1] == "/" {
                        out.append("  ")
                        i += 2
                        break
                    }
                    out.append(chars[i] == "\n" ? "\n" : " ")
                    i += 1
                }
                continue
            }
            if ch == "\"" || ch == "`" {
                let quote = ch
                out.append(" ")
                i += 1
                while i < chars.count {
                    if chars[i] == "\\" && quote == "\"" {
                        out.append("  ")
                        i += 2
                        continue
                    }
                    if chars[i] == quote {
                        out.append(" ")
                        i += 1
                        break
                    }
                    out.append(chars[i] == "\n" ? "\n" : " ")
                    i += 1
                }
                continue
            }
            out.append(ch)
            i += 1
        }
        return out
    }

}
