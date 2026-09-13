import Foundation
import Testing

/// 单一主操作必须走 `meterPrimaryActionBar()`，底栏背景才能铺进 Home Indicator。
///
/// 提交闸 `scripts/check-source-invariants.py` 扫同一套判据。改了两边一起改。
struct PrimaryActionBarGuardrailTests {
    private static let inset = try! NSRegularExpression(
        pattern: #"\.safeArea(?:Inset|Bar)\(\s*edge:\s*\.bottom"#
    )

    @Test("Features 不自己写底部 inset / bar")
    func featuresDoNotHandRollBottomActionBars() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources/MeterFeatures"]
        ) {
            if file.lastPathComponent == "RootView.swift" { continue }
            offenders.append(contentsOf: try Self.offenders(in: file, repoRoot: repoRoot))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("主操作和测试连接是同一颗胶囊")
    func primaryActionsShareCapsuleChrome() throws {
        let bar = try GuardrailSourceScan.sourceText(named: "PrimaryActionBar.swift")
        let fill = try GuardrailSourceScan.sourceText(named: "FillProgressButton.swift")
        #expect(bar.contains("buttonStyle(.borderedProminent)"))
        #expect(bar.contains("controlSize(.large)"))
        #expect(bar.contains("buttonBorderShape(.capsule)"))
        #expect(bar.contains("scrollEdgeEffectHidden"))
        #expect(bar.contains("ignoresSafeArea"))
        #expect(bar.contains("ignoresKeyboard"))
        #expect(bar.contains("contentMargins"))
        #expect(bar.contains("primaryActionMinHeight"))
        #expect(bar.contains("func meterInlineActionStyle()"))
        #expect(bar.contains("controlSize(.regular)"))
        #expect(bar.contains("meterSheetCloseHosted, isVisible"))
        #expect(!bar.contains("meterSheetCloseHosted, true"))
        #expect(fill.contains("controlSize(.large)"))
        #expect(fill.contains("Capsule()"))
        #expect(!fill.contains("RoundedRectangle"))
        #expect(!fill.contains("MeterRadius"))
    }

    @Test("Keychain 说明不在主操作条里，不能把测试连接顶上去")
    func keychainExplainerIsNotInActionBar() throws {
        let text = try GuardrailSourceScan.sourceText(named: "SetupCredentialsStepView.swift")
        guard let barRange = text.range(of: ".meterPrimaryActionBar") else {
            Issue.record("SetupCredentialsStepView 必须走 meterPrimaryActionBar")
            return
        }
        let sheetMarker = ".sheet(isPresented: $isShowingKeychainExplainer)"
        let barEnd = text.range(of: sheetMarker)?.lowerBound ?? text.endIndex
        let barBlock = text[barRange.lowerBound..<barEnd]
        #expect(
            !barBlock.contains("什么是 Keychain？"),
            "「什么是 Keychain？」放凭据页脚，不要堆在主按钮下面"
        )
        #expect(text.contains("什么是 Keychain？"))
    }

    @Test("凭据输入没有 placeholder")
    func credentialInputsHaveNoPlaceholder() throws {
        let files = [
            "SetupCredentialsStepView.swift",
            "GalleryCredentialFieldsView.swift",
            "CredentialFieldRow.swift",
        ]
        var offenders: [String] = []
        for name in files {
            let text = try GuardrailSourceScan.sourceText(named: name)
            if text.contains("prompt:") {
                offenders.append("\(name) 凭据输入不许有 prompt / placeholder")
            }
            if text.contains("SecureField")
                || text.contains("isSecureTextEntry")
                || text.contains("CredentialSecretField") {
                offenders.append("\(name) 凭据输入不要掩码，一律 TextField")
            }
        }
        let row = try GuardrailSourceScan.sourceText(named: "CredentialFieldRow.swift")
        if !row.contains("TextField") {
            offenders.append("CredentialFieldRow 必须自己放 TextField")
        }
        if !row.contains("minTap") || !row.contains("onTapGesture") {
            offenders.append("CredentialFieldRow 输入行要 44pt 热区，标题也要能点")
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("凭据步测试连接不跟着键盘抬")
    func credentialsPrimaryActionIgnoresTheKeyboard() throws {
        let credentials = try GuardrailSourceScan.sourceText(named: "SetupCredentialsStepView.swift")
        let inbox = try GuardrailSourceScan.sourceText(named: "InboxHandoffStepView.swift")
        let sheet = try GuardrailSourceScan.sourceText(named: "UsageSetupSheet.swift")
        let presentation = try GuardrailSourceScan.sourceText(named: "UsageSetupPresentation.swift")
        let chrome = try GuardrailSourceScan.sourceText(named: "ContainerChromeHeight.swift")
        let wizard = try GuardrailSourceScan.sourceText(named: "SetupWizardView.swift")
        let guide = try GuardrailSourceScan.sourceText(named: "SetupGuideStepView.swift")
        let confirm = try GuardrailSourceScan.sourceText(named: "AddProviderConfirmSheet.swift")
        #expect(credentials.contains("ignoresKeyboard: true"))
        #expect(inbox.contains("ignoresKeyboard: true"))
        #expect(guide.contains("ignoresKeyboard: true"))
        #expect(confirm.contains("meterPrimaryActionBar"))
        #expect(confirm.contains("meterDrawerChrome"))
        #expect(sheet.contains("meterContainerChromeHeight"))
        #expect(!sheet.contains("prefersExpanded"))
        #expect(!presentation.contains("prefersExpanded"))
        #expect(!presentation.contains("selection:"))
        #expect(presentation.contains("meterDrawerChrome"))
        #expect(wizard.contains("meterNavigationContainerBackground"))
        #expect(wizard.contains("meterGroupedBackground"))
        #expect(chrome.contains("ignoresSafeArea(.keyboard)"))
        #expect(chrome.contains("acceptedChromeHeight"))
    }

    private static func offenders(in file: URL, repoRoot: URL) throws -> [String] {
        let original = try String(contentsOf: file, encoding: .utf8)
        let masked = maskCommentsAndStrings(original)
        let ns = masked as NSString
        let matches = inset.matches(in: masked, range: NSRange(location: 0, length: ns.length))
        let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        return matches.map { match in
            let prefix = ns.substring(to: match.range.location)
            let line = prefix.filter { $0 == "\n" }.count + 1
            return "\(relative):\(line) 主操作底栏请用 meterPrimaryActionBar()"
        }
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
