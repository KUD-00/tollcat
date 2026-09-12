import Foundation
import Testing

/// 下拉刷新不许出现系统转圈。Features 只能走 `meterRefreshable`，转圈藏在 Design 里。
/// 工具栏和详情的刷新按钮走 `MeterRefreshGlyph`，箭头转到完成。
///
/// 提交闸 `scripts/check-source-invariants.py` 扫同一套判据。改了两边一起改。
struct RefreshableGuardrailTests {
    @Test("Features 不直接用系统 refreshable")
    func featuresDoNotCallSystemRefreshable() throws {
        var offenders: [String] = []
        let repoRoot = GuardrailSourceScan.repoRoot
        for file in try GuardrailSourceScan.swiftFiles(
            under: ["App", "Widget", "Packages/MeterKit/Sources/MeterFeatures"]
        ) {
            let text = try String(contentsOf: file, encoding: .utf8)
            guard text.contains(".refreshable") else { continue }
            let relative = file.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
            for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                if line.contains(".refreshable") {
                    offenders.append("\(relative):\(index + 1) 下拉刷新走 meterRefreshable，不要直接 .refreshable。")
                }
            }
        }
        #expect(offenders.isEmpty, Comment(rawValue: offenders.joined(separator: "\n")))
    }

    @Test("meterRefreshable 藏掉系统转圈")
    func meterRefreshableHidesSystemSpinner() throws {
        let text = try GuardrailSourceScan.sourceText(named: "MeterRefreshable.swift")
        #expect(text.contains(".refreshable"))
        #expect(text.contains("UIRefreshControl"))
        #expect(text.contains("tintColor = .clear"))
        #expect(text.contains("subview.alpha = 0"))
    }

    @Test("仪表和服务都走 meterRefreshable")
    func dashboardAndServicesUseMeterRefreshable() throws {
        let dashboard = try GuardrailSourceScan.sourceText(named: "DashboardView.swift")
        let pad = try GuardrailSourceScan.sourceText(named: "DashboardPadLayout.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        #expect(dashboard.contains("meterRefreshable"))
        #expect(pad.contains("meterRefreshable"))
        #expect(services.contains("meterRefreshable"))
    }

    @Test("刷新按钮走 MeterRefreshGlyph，转到完成")
    func refreshButtonsUseMeterRefreshGlyph() throws {
        let dashboard = try GuardrailSourceScan.sourceText(named: "DashboardView.swift")
        let services = try GuardrailSourceScan.sourceText(named: "ServicesView.swift")
        let detail = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(dashboard.contains("MeterRefreshGlyph"))
        #expect(dashboard.contains("meterRefreshing"))
        #expect(services.contains("MeterRefreshGlyph"))
        #expect(services.contains("meterRefreshing"))
        #expect(detail.contains("MeterRefreshGlyph"))
        #expect(!dashboard.contains("Image(systemName: \"arrow.clockwise\")"))
        #expect(!services.contains("Image(systemName: \"arrow.clockwise\")"))
        #expect(!detail.contains("Image(systemName: \"arrow.clockwise\")"))
    }
}

