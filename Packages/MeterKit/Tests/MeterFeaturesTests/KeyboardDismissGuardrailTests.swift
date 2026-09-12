import Foundation
import Testing

/// 有软件键盘的屏幕必须能关掉键盘。
/// SwiftUI 输入挂 `meterKeyboardDismiss()`；`UITextField` 自己挂完成附件栏。
///
/// 提交闸 `scripts/check-source-invariants.py` 扫同一套判据。改了两边一起改。
struct KeyboardDismissGuardrailTests {
    private static let input = try! NSRegularExpression(
        pattern: #"\b(?:TextField|SecureField|TextEditor)\s*\("#
    )
    private static let uiTextField = try! NSRegularExpression(
        pattern: #"\bUITextField\s*\("#
    )

    @Test("完成挂在软件键盘上，不进导航栏")
    func dismissControlSitsOnTheKeyboard() throws {
        let text = try GuardrailSourceScan.sourceText(named: "KeyboardDismiss.swift")
        let masked = Self.maskCommentsAndStrings(text)
        #expect(masked.contains("placement: .keyboard"))
        #expect(!masked.contains("confirmationAction"))
    }

    @Test("收起时等键盘动画走完再拆完成栏")
    func hidesAccessoryAfterKeyboardDidHide() throws {
        let text = try GuardrailSourceScan.sourceText(named: "KeyboardDismiss.swift")
        let masked = Self.maskCommentsAndStrings(text)
        #expect(masked.contains("keyboardDidHideNotification"))
        #expect(!masked.contains("keyboardWillHideNotification"))
        #expect(masked.contains("disablesAnimations"))
    }

    @Test("TextField / SecureField / TextEditor 都挂了关闭键盘")
    func textInputsDismissTheSoftwareKeyboard() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources"]
        ) {
            offenders.append(contentsOf: try Self.offenders(in: file, repoRoot: repoRoot))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("UITextField 必须自己挂完成附件栏")
    func uiTextFieldsInstallADoneAccessory() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources"]
        ) {
            offenders.append(contentsOf: try Self.uiTextFieldOffenders(in: file, repoRoot: repoRoot))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    private static func offenders(in file: URL, repoRoot: URL) throws -> [String] {
        let original = try String(contentsOf: file, encoding: .utf8)
        let masked = maskCommentsAndStrings(original)
        let ns = masked as NSString
        let matches = input.matches(in: masked, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }
        if masked.contains("meterKeyboardDismiss") { return [] }
        let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        let prefix = ns.substring(to: matches[0].range.location)
        let line = prefix.filter { $0 == "\n" }.count + 1
        return [
            "\(relative):\(line) TextField/SecureField/TextEditor 必须配合 meterKeyboardDismiss()。"
            + "软件键盘没有关闭键；完成贴在键盘右上，见 KeyboardDismiss。"
        ]
    }

    private static func uiTextFieldOffenders(in file: URL, repoRoot: URL) throws -> [String] {
        let original = try String(contentsOf: file, encoding: .utf8)
        let masked = maskCommentsAndStrings(original)
        let ns = masked as NSString
        let matches = uiTextField.matches(in: masked, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }
        let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        let prefix = ns.substring(to: matches[0].range.location)
        let line = prefix.filter { $0 == "\n" }.count + 1
        if !masked.contains("inputAccessoryView") {
            return [
                "\(relative):\(line) UITextField 必须自己挂 inputAccessoryView 完成键。"
                    + "SwiftUI 的键盘工具栏只跟 TextField 走，API token 那种掩码框会漏掉关闭键。"
            ]
        }
        if !original.contains("L(\"完成\")") {
            return [
                "\(relative):\(line) UITextField 附件栏的完成必须走 L(\"完成\")，"
                    + "和 SwiftUI 键盘工具栏同一条文案。"
            ]
        }
        return []
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
