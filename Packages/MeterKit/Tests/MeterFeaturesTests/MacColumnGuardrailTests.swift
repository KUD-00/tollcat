import Foundation
import Testing
@testable import MeterFeatures

/// Mac 可达的页面要长成 iOS 那种分组卡片，推页要走列内栈。
/// 这两条都栽过：`.insetGrouped` 在 Mac 被别名映射成密表 `.inset`；
/// 裸 `NavigationLink` 在 split 的 detail 列里会被系统提级、接管整个 detail 区。
struct MacColumnGuardrailTests {
    /// 分组渲染的扫描范围：Mac 分栏和 sheet 里能看到的五个目录。
    private static let groupedFolders = [
        "Packages/MeterKit/Sources/MeterFeatures/Settings",
        "Packages/MeterKit/Sources/MeterFeatures/Developer",
        "Packages/MeterKit/Sources/MeterFeatures/Services",
        "Packages/MeterKit/Sources/MeterFeatures/Dashboard",
        "Packages/MeterKit/Sources/MeterFeatures/Setup",
    ]

    /// 列内推进的扫描范围。仪表盘的路线链接走 `DashboardRouteLink`
    /// （Mac 推列内手工栈，其他平台回落系统栈），裸 NavigationLink 只剩它内部那一处。
    private static let pushFolders = [
        "Packages/MeterKit/Sources/MeterFeatures/Dashboard",
        "Packages/MeterKit/Sources/MeterFeatures/Settings",
        "Packages/MeterKit/Sources/MeterFeatures/Developer",
        "Packages/MeterKit/Sources/MeterFeatures/Services",
    ]

    @Test("Mac 可达页面不直接写 insetGrouped，分组页一律 MeterGroupedList")
    func groupedPagesUseMeterGroupedList() throws {
        // DashboardView 的手机单列分支（usesPadChrome == false）是唯一的合法字面量；
        // SetupStepText 的 insetGrouped 只出现在预览里。Form 类页面写 `.formStyle(.grouped)`。
        let exempt: Set<String> = ["DashboardView.swift", "SetupStepText.swift"]
        for url in try GuardrailSourceScan.swiftFiles(under: Self.groupedFolders)
        where !exempt.contains(url.lastPathComponent) {
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(
                !text.contains(".listStyle(.insetGrouped)"),
                "\(url.lastPathComponent) 直接用了 insetGrouped——Mac 上是密表，改用 MeterGroupedList"
            )
        }
    }

    @Test("分组容器必须挂 meterGroupedRowButtons：裸按钮在 Mac 会渲成 NSButton 凸起胶囊")
    func groupedContainersCarryRowButtonDefault() throws {
        // MeterGroupedList 自带默认值；DashboardView 是手机单列分支；
        // SetupStepText 的 insetGrouped 只出现在预览里。
        let exempt: Set<String> = ["DashboardView.swift", "SetupStepText.swift"]
        for url in try GuardrailSourceScan.swiftFiles(under: Self.groupedFolders)
        where !exempt.contains(url.lastPathComponent) {
            let text = try String(contentsOf: url, encoding: .utf8)
            let hasGroupedContainer = text.contains(".formStyle(.grouped)")
                || text.contains(".listStyle(.insetGrouped)")
            if hasGroupedContainer {
                #expect(
                    text.contains(".meterGroupedRowButtons()"),
                    "\(url.lastPathComponent) 有分组容器但没挂 meterGroupedRowButtons()——Mac 上裸按钮会渲成凸起胶囊"
                )
            }
        }
        let grouped = try GuardrailSourceScan.sourceText(named: "MeterGroupedList.swift")
        #expect(grouped.contains(".meterGroupedRowButtons()"))
    }

    @Test("grouped Form 必须挂 meterGroupedSectionCard：系统 section 卡只会比画布更暗")
    func groupedFormsCarrySectionCard() throws {
        for url in try GuardrailSourceScan.swiftFiles(under: Self.groupedFolders) {
            let text = try String(contentsOf: url, encoding: .utf8)
            guard text.contains(".formStyle(.grouped)") else { continue }
            #expect(
                text.contains(".meterGroupedSectionCard()"),
                "\(url.lastPathComponent) 有 grouped Form 但没挂 meterGroupedSectionCard()——Mac 上 section 卡会比画布更暗"
            )
        }
        let grouped = try GuardrailSourceScan.sourceText(named: "MeterGroupedList.swift")
        #expect(grouped.contains(".meterGroupedSectionCard()"))
    }

    @Test("不用 inline Picker：macOS 26 的 Menu 里它整组菜单项渲成禁用灰")
    func noInlinePickers() throws {
        for url in try GuardrailSourceScan.swiftFiles(under: ["Packages/MeterKit/Sources/MeterFeatures"]) {
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(
                !text.contains(".pickerStyle(.inline)"),
                "\(url.lastPathComponent) 用了 inline Picker——Mac 的 Menu 里点不动，菜单选项改用 Button + 勾选"
            )
        }
    }

    @Test("设置 / 开发页不写裸 NavigationLink，推页走 MeterColumnLink")
    func pushesGoThroughColumnLinks() throws {
        // SettingsView / ServicesView 的手机栈分支（usesPadChrome == false）是唯一的合法裸链接。
        let exempt: Set<String> = ["SettingsView.swift", "ServicesView.swift", "DashboardRouteLink.swift"]
        for url in try GuardrailSourceScan.swiftFiles(under: Self.pushFolders)
        where !exempt.contains(url.lastPathComponent) {
            let text = try String(contentsOf: url, encoding: .utf8)
            #expect(
                !text.contains("NavigationLink("),
                "\(url.lastPathComponent) 用了裸 NavigationLink——Mac 列里会被整区接管，改用 MeterColumnLink / MeterColumnPushLink"
            )
        }
    }
}
