import Foundation

/// Guardrail 测试定位源码的唯一入口。
///
/// 点名文件一律**按文件名递归找**，不锁目录——文件搬家不该弄断闸，
/// 改名或删除才该（那时命中数变化，闸会明确报错）。
/// 目录级不变量用 `swiftFiles(under:)` 全量扫。
enum GuardrailSourceScan {
    static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // MeterFeaturesTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // MeterKit
            .deletingLastPathComponent()   // Packages
            .deletingLastPathComponent()   // repo root
    }

    static func swiftFiles(under folders: [String]) throws -> [URL] {
        var files: [URL] = []
        var stack = folders.map { repoRoot.appending(path: $0) }
        while let directory = stack.popLast() {
            let children = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            for child in children {
                if (try child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    stack.append(child)
                } else if child.pathExtension == "swift" {
                    files.append(child)
                }
            }
        }
        return files
    }

    /// 在 MeterKit 的 Sources 下按文件名找唯一一个源文件并读出正文。
    static func sourceText(named fileName: String) throws -> String {
        let matches = try swiftFiles(under: ["Packages/MeterKit/Sources"])
            .filter { $0.lastPathComponent == fileName }
        guard matches.count == 1, let url = matches.first else {
            throw GuardrailScanError(
                message: "按文件名找 \(fileName)：命中 \(matches.count) 个。"
                    + "文件被改名/删除/复制时，点名它的 guardrail 要一起更新。"
            )
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// 长度不变，注释和字符串抹成空格。扫禁词时不要被注释里的「不要写 X」误伤。
    static func maskCommentsAndStrings(_ text: String) -> String {
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

struct GuardrailScanError: Error, CustomStringConvertible {
    var message: String
    var description: String { message }
}
