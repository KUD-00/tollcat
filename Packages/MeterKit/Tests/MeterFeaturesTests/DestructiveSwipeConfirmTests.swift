import Foundation
import Testing

struct DestructiveSwipeConfirmTests {
    @Test("划掉订阅先确认")
    func subscriptionSwipeConfirms() throws {
        let text = try GuardrailSourceScan.sourceText(named: "ProviderDetailView.swift")
        #expect(text.contains("subscriptionPendingDeletion"))
        #expect(text.contains("L(\"删除这笔订阅？\")"))
        #expect(text.contains("confirmationDialog"))
        #expect(text.contains("subscriptionPendingDeletion = item.id"))
        #expect(!text.contains("swipeActions") || text.contains("subscriptionPendingDeletion = item.id"))
    }

    @Test("划掉投递 key 先确认")
    func ingestKeySwipeConfirms() throws {
        let text = try GuardrailSourceScan.sourceText(named: "InboxSettingsView.swift")
        #expect(text.contains("keyPendingRevocation"))
        #expect(text.contains("L(\"吊销这把投递 key？\")"))
        #expect(text.contains("confirmationDialog"))
    }

    @Test("SafariLink 说明会离开 App")
    func safariLinkAnnouncesSafari() throws {
        let text = try GuardrailSourceScan.sourceText(named: "SafariLink.swift")
        #expect(text.contains("accessibilityHint"))
        #expect(text.contains("L(\"在 Safari 打开\")"))
    }

    /// 芯片本身搬去了 `MeterSelectionChip`（筛选面板两行 chip 共用一套版式），
    /// 热区这条闸跟着搬——守的是「那颗胶囊点得到」，不是它住在哪个文件里。
    @Test("筛选芯片热区 44pt")
    func monthChipsMeetMinTap() throws {
        let chip = try GuardrailSourceScan.sourceText(named: "MeterSelectionChip.swift")
        #expect(chip.contains("MeterSpacing.minTap"))
        let sheet = try GuardrailSourceScan.sourceText(named: "DashboardFilterSheet.swift")
        #expect(sheet.contains("MeterSelectionChip"))
    }
}
