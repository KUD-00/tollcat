import Foundation
import Testing

/// iPhone 抽屉走 detent；横屏 iPad 走 form / page。Features 不许手写呈现修饰符。
///
/// 判据和 `scripts/check-source-invariants.py` 的 `check_drawer_chrome` 同一套，
/// 改了两边一起改。
struct DrawerChromeGuardrailTests {
    @Test("iPad 外壳不用 detent，走 form / page，关掉抓手")
    func padChromeUsesPresentationSizingNotDetents() throws {
        let source = try GuardrailSourceScan.sourceText(named: "DrawerChrome.swift")
        let pad = try Self.methodBody(named: "pad", in: source)
        let phone = try Self.methodBody(named: "phone", in: source)
        #expect(!pad.contains("presentationDetents"))
        #expect(pad.contains("presentationSizing"))
        #expect(pad.contains(".form"))
        #expect(pad.contains(".page"))
        #expect(pad.contains("presentationDragIndicator(.hidden)"))
        #expect(!pad.contains("presentationDragIndicator(.visible)"))
        #expect(phone.contains("presentationDetents"))
        #expect(phone.contains("presentationDragIndicator(.visible)"))
        #expect(!phone.contains("presentationSizing"))
    }

    @Test("Features 不要手写 sheet 呈现修饰符")
    func featuresDoNotHandWritePresentationChrome() throws {
        var offenders: [String] = []
        let forbidden = [
            "presentationDetents",
            "presentationSizing",
            "presentationDragIndicator",
            "presentationBackground",
        ]
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources/MeterFeatures"]
        ) {
            let text = try String(contentsOf: file, encoding: .utf8)
            let masked = GuardrailSourceScan.maskCommentsAndStrings(text)
            for token in forbidden where masked.contains(token) {
                offenders.append("\(file.lastPathComponent) 不要手写 \(token)")
            }
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("连接参考 iPad 走 page，手机按内容收矮")
    func usageSetupUsesPageOnPad() throws {
        let presentation = try GuardrailSourceScan.sourceText(named: "UsageSetupPresentation.swift")
        #expect(presentation.contains(".page"))
        #expect(presentation.contains(".expandable"))
        #expect(presentation.contains("usesPadChrome ? .page"))
    }

    /// 宽壳上这面是个对话框：只占内容要的那么大。`.page` 会给一张固定大页，
    /// 预览和三行动作摆完之后剩一大片空。手机没有「按内容收宽」这回事，仍是满屏。
    @Test("分享卡：宽壳按内容定尺寸，手机满屏")
    func shareCardFitsItsContentOnWideShells() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ShareCardSheet.swift")
        #expect(text.contains("meterDrawerChrome(usesPadChrome ? .fitted : .page"))
        #expect(!text.contains("meterDrawerChrome(.large"))
        // `.fitted` 量的是理想尺寸，List / Form 报 0：这面不许用它们**排版**。
        // 判据扫的是掩过注释的源码——注释里提一句「行的样子和 MeterGroupedList 一样」
        // 是说明，不是用法。（取景框那条闸故意连注释一起扫，那是另一种意图：拦渐变。）
        #expect(!GuardrailSourceScan.maskCommentsAndStrings(text).contains("MeterGroupedList"))
    }

    @Test("筛选 iPad 是 popover，不套 sheet 外壳")
    func filterSkipsSheetChromeOnPad() throws {
        let filter = try GuardrailSourceScan.sourceText(named: "DashboardFilterSheet.swift")
        let popover = try GuardrailSourceScan.sourceText(named: "PadPopoverOrSheet.swift")
        #expect(filter.contains("meterPhoneDrawerChrome"))
        #expect(!filter.contains("meterDrawerChrome(.large, usesPadChrome: usesPadChrome)"))
        #expect(popover.contains("popover"))
        #expect(popover.contains("meterPhoneDrawerChrome"))
    }

    @Test("DrawerHeight 有 page 档")
    func drawerHeightHasPageCase() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DrawerHeight.swift")
        #expect(text.contains("case page"))
    }

    private static func methodBody(named name: String, in source: String) throws -> String {
        let needle = "func \(name)("
        guard let start = source.range(of: needle) else {
            throw GuardrailScanError(message: "找不到 func \(name)(")
        }
        guard let brace = source[start.lowerBound...].firstIndex(of: "{") else {
            throw GuardrailScanError(message: "func \(name) 没有 {")
        }
        var depth = 0
        var index = brace
        while index < source.endIndex {
            let character = source[index]
            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return String(source[brace...index])
                }
            }
            index = source.index(after: index)
        }
        throw GuardrailScanError(message: "func \(name) 括号不配对")
    }
}
