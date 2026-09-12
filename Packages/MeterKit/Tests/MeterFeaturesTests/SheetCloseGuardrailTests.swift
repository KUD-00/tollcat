import Foundation
import Testing

/// 关掉 sheet 走 `meterSheetClose`：iOS 是系统 X（`Button(role: .close)`），
/// Mac 的 sheet 没有导航栏，它变成底栏左边的「取消」。单一主操作走底栏。
/// 导航栏不许手写「取消」文字按钮。对话框里的 `role: .cancel` 仍走文案。
///
/// 提交闸 `scripts/check-source-invariants.py` 扫同一套判据。改了两边一起改。
struct SheetCloseGuardrailTests {
    private static let textCancel = try! NSRegularExpression(
        pattern: #"Button\(\s*L\(\s*"取消"\s*\)\s*\)"#
    )

    @Test("导航栏不手写取消文字")
    func toolbarDoesNotSpellCancel() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources"]
        ) {
            offenders.append(contentsOf: try Self.offenders(in: file, repoRoot: repoRoot))
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("加一笔订阅和编辑订阅走系统关闭")
    func subscriptionSheetsUseSystemClose() throws {
        let editor = try GuardrailSourceScan.sourceText(named: "SubscriptionEditorSheet.swift")
        #expect(editor.contains("meterSheetClose("))
        #expect(editor.contains("meterSheetTitle("))
        #expect(!editor.contains("cancellationAction"))
    }

    @Test("Features 不直接写 Button(role: .close)：Mac 会把它甩到另起的底栏")
    func featuresRouteCloseThroughMeterSheetClose() throws {
        var offenders: [String] = []
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources/MeterFeatures"]
        ) {
            let text = try String(contentsOf: file, encoding: .utf8)
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            if masked.contains("Button(role: .close)") {
                offenders.append("\(file.lastPathComponent) 关掉 sheet 走 meterSheetClose，不要直接写 Button(role: .close)")
            }
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
        let design = try GuardrailSourceScan.sourceText(named: "SheetClose.swift")
        #expect(design.contains("Button(role: .close"))
        #expect(design.contains("cancelAction"))
    }

    @Test("筛选关掉走系统关闭，确认在底栏")
    func filterSheetUsesSystemCloseAndBottomApply() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DashboardFilterSheet.swift")
        #expect(text.contains("meterSheetClose"))
        #expect(text.contains("meterSheetTitle("))
        #expect(text.contains("meterPrimaryActionBar"))
        #expect(text.contains("L(\"用这个\")"))
        #expect(!text.contains("cancellationAction"))
        #expect(!text.contains("confirmationAction"))
    }

    @Test("有主按钮的抽屉走同一套外壳")
    func actionDrawersShareChrome() throws {
        let files = [
            "AddProviderConfirmSheet.swift",
            "SubscriptionEditorSheet.swift",
            "UsageSetupPresentation.swift",
            "UsageGuideDrawerView.swift",
            "WhatsNewDrawerView.swift",
            "DashboardFilterSheet.swift",
            "ShareCardSheet.swift",
        ]
        var offenders: [String] = []
        for name in files {
            let text = try GuardrailSourceScan.sourceText(named: name)
            if name == "DashboardFilterSheet.swift" {
                if !text.contains("meterPhoneDrawerChrome") {
                    offenders.append("\(name) iPad 是 popover，走 meterPhoneDrawerChrome()")
                }
            } else if !text.contains("meterDrawerChrome") {
                offenders.append("\(name) 必须走 meterDrawerChrome()")
            }
        }
        let editor = try GuardrailSourceScan.sourceText(named: "SubscriptionEditorSheet.swift")
        if !editor.contains("ignoresKeyboard: true") {
            offenders.append("SubscriptionEditorSheet 必须 ignoresKeyboard")
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("分享卡关掉走系统关闭，走抽屉外壳")
    func shareCardUsesSystemCloseAndDrawerChrome() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ShareCardSheet.swift")
        #expect(text.contains("meterSheetClose"))
        #expect(text.contains("meterSheetTitle("))
        #expect(text.contains("meterDrawerChrome(usesPadChrome ? .fitted : .page"))
        #expect(!text.contains("presentationDetents"))
        #expect(!text.contains("presentationSizing"))
        #expect(!text.contains("xmark"))
        #expect(!text.contains("cancellationAction"))
    }

    @Test("向导、提醒预授权、更新说明、利用指南都能点关闭")
    func remainingDrawersUseSystemClose() throws {
        let files = [
            "SetupWizardView.swift",
            "SetupWizardPadLayout.swift",
            "ReminderOptInSheet.swift",
            "UsageGuideDrawerView.swift",
            "WhatsNewDrawerView.swift",
        ]
        var offenders: [String] = []
        for name in files {
            let text = try GuardrailSourceScan.sourceText(named: name)
            if !text.contains("meterSheetClose") {
                offenders.append("\(name) 必须走 meterSheetClose")
            }
            if !text.contains("meterSheetTitle") && name != "SetupWizardView.swift" {
                offenders.append("\(name) 必须走 meterSheetTitle")
            }
        }
        let wizard = try GuardrailSourceScan.sourceText(named: "SetupWizardView.swift")
        if !wizard.contains("navigationSubtitle") {
            offenders.append("SetupWizardView 手机向导要有第几步")
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("管理凭据从右侧推进，不是抽屉")
    func credentialManagementPushesInsteadOfDrawer() throws {
        let text = try GuardrailSourceScan.sourceText(named: "CredentialManagementSheet.swift")
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(detail.contains("NavigationLink"))
        #expect(detail.contains("CredentialManagementSheet"))
        #expect(!detail.contains("isPresentingCredentialManagement"))
        #expect(!text.contains("meterDrawerChrome"))
        #expect(!text.contains("meterPrimaryActionBar"))
        #expect(!text.contains("meterSheetClose"))
        #expect(!text.contains("cancellationAction"))
    }

    private static func offenders(in file: URL, repoRoot: URL) throws -> [String] {
        let original = try String(contentsOf: file, encoding: .utf8)
        let ns = original as NSString
        let matches = textCancel.matches(in: original, range: NSRange(location: 0, length: ns.length))
        let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
        return matches.map { match in
            let prefix = ns.substring(to: match.range.location)
            let line = prefix.filter { $0 == "\n" }.count + 1
            return "\(relative):\(line) 关掉 sheet 用 Button(role: .close)。"
                + "不要手写 Button(L(\"取消\"))。"
                + "confirmationDialog 里写 Button(L(\"取消\"), role: .cancel)。"
        }
    }

}
