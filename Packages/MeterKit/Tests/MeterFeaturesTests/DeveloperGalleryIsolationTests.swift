#if DEBUG
import Foundation
import Testing
import MeterCore
import MeterDesign
@testable import MeterFeatures
@testable import MeterModules

@MainActor
struct DeveloperGalleryIsolationTests {
    @Test("画廊只构造值对象，不改真实 store")
    func galleryFixturesDoNotWriteStore() {
        let model = DashboardModel.preview
        let snapshotsBefore = model.debugReadingCount
        let subscriptionsBefore = model.subscriptions.count
        let totalBefore = model.monthToDate?.totalUSD
        let persistenceBefore = model.persistenceToken

        let constructed = GalleryFixtures.constructAll()

        #expect(constructed > 0)
        #expect(model.debugReadingCount == snapshotsBefore)
        #expect(model.subscriptions.count == subscriptionsBefore)
        #expect(model.monthToDate?.totalUSD == totalBefore)
        #expect(model.persistenceToken == persistenceBefore)
    }

    @Test("开发层注册表覆盖画廊和时间覆盖")
    func registryIncludesRequiredTools() {
        let ids = DeveloperToolID.allCases
        #expect(ids.contains(.gallery))
        #expect(ids.contains(.dashboardLab))
        #expect(ids.contains(.clock))
        #expect(ids.contains(.data))
        #expect(ids.contains(.refreshLog))
        #expect(ids.contains(.buildInfo))
        #expect(GalleryItemID.allCases.contains(.empty))
        #expect(GalleryItemID.allCases.contains(.errors))
        #expect(GalleryItemID.allCases.contains(.amounts))
        #expect(!GalleryItemID.allCases.map(\.rawValue).contains("confidence"))
        #expect(GalleryItemID.allCases.contains(.charts))
        #expect(GalleryItemID.allCases.contains(.setupGuides))
        #expect(GalleryItemID.allCases.contains(.usageGuides))
        #expect(GalleryItemID.allCases.contains(.verifyConnection))
        #expect(GalleryItemID.allCases.contains(.refresh))
        #expect(GalleryItemID.allCases.contains(.credentialFields))
        #expect(GalleryItemID.allCases.contains(.tips))
        #expect(Set(GallerySection.allCases.flatMap(\.items)) == Set(GalleryItemID.allCases))
        #expect(Set(DeveloperToolSection.allCases.flatMap(\.items)) == Set(DeveloperToolID.allCases))
    }

    @Test("金额画廊有数字滚动和构成条的可交互演示")
    func amountGalleryHasMotionDemo() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryAmountStatesView.swift")
        #expect(text.contains("换一个数字"))
        #expect(text.contains("自动循环"))
        #expect(text.contains("MonthToDateModuleView"))
        #expect(text.contains("CompositionModuleView"))
        #expect(text.contains("67.20"))
        // 首屏已经不画「含估算」，画廊里再翻精度不会有可见变化。
        #expect(!text.contains("改成估算"))
        #expect(!text.contains("改成精确"))
    }

    @Test("图表画廊把空、一天、整月摊开，不靠按钮切换")
    func chartGalleryEnumeratesVariants() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryChartStatesView.swift")
        #expect(text.contains("一天"))
        #expect(text.contains("整月"))
        #expect(text.contains("一个点"))
        #expect(text.contains("一条折线"))
        #expect(!text.contains("换一组每日花费"))
        #expect(!text.contains("换一组余额"))
        #expect(!text.contains("spendIndex"))
    }

    @Test("猫猫画廊有预设和可拧的高级页")
    func catGalleryHasPresetsAndAdvancedStudio() throws {
        let main = try GuardrailSourceScan.sourceText(named: "GalleryCatStatesView.swift")
        let advanced = try GuardrailSourceScan.sourceText(named: "GalleryCatAdvancedView.swift")
        #expect(main.contains("预设"))
        #expect(main.contains("全部表情"))
        #expect(main.contains("高级"))
        #expect(main.contains("眼睛"))
        #expect(main.contains("嘴"))
        #expect(main.contains("挂件"))
        #expect(advanced.contains("Slider"))
        #expect(advanced.contains("眼睛"))
        #expect(advanced.contains("嘴"))
        #expect(advanced.contains("挂件"))
        #expect(advanced.contains("姿势"))
        #expect(advanced.contains("尺寸"))
    }

    @Test("刷新按钮画廊能演示箭头转到结束")
    func refreshGalleryHasMotionDemo() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryRefreshView.swift")
        #expect(text.contains("MeterRefreshGlyph"))
        #expect(text.contains("meterRefreshing"))
        #expect(text.contains("转一次"))
        #expect(text.contains("isRefreshing"))
    }

    @Test("测试连接画廊能演示铺色和成败")
    func verifyConnectionGalleryHasMotionDemo() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryVerifyConnectionView.swift")
        #expect(text.contains("FillProgressButton"))
        #expect(text.contains("测一次成功"))
        #expect(text.contains("测一次失败"))
        #expect(text.contains("sensoryFeedback"))
        #expect(text.contains("SetupVerifyResultView"))
        #expect(text.contains("凭据"))
        #expect(text.contains("绿色"))
    }

    @Test("打赏画廊能演示付款成功后猫变大和档位收走")
    func tipGalleryHasCelebrationDemo() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryTipStatesView.swift")
        #expect(text.contains("TipTreatView"))
        #expect(text.contains("catTipCelebrating"))
        #expect(text.contains("付款成功"))
        #expect(text.contains("写好了"))
        #expect(text.contains("meterPrimaryActionBar"))
        #expect(text.contains(".snappy"))
    }

    @Test("凭据输入画廊有两行字段和粘贴")
    func credentialFieldsGalleryHasPaste() throws {
        let text = try GuardrailSourceScan.sourceText(named: "GalleryCredentialFieldsView.swift")
        #expect(text.contains("CredentialFieldRow"))
        #expect(text.contains("onPaste"))
        #expect(text.contains("SystemClipboard"))
        #expect(text.contains("凭据"))
        #expect(!text.contains("CredentialSecretField"))
    }

    @Test("实验室目录覆盖全部模块，不另开名单")
    func labIndexCoversDefaultOrder() {
        let listed = Set(DashboardLabSection.allCases.flatMap(\.ids))
        #expect(listed == Set(DashboardModuleID.defaultOrder))
        #expect(listed.count == DashboardModuleID.defaultOrder.count)
    }

    @Test("设计稿每块模块都有内容")
    func labFixturesCoverEveryModule() {
        let fixtures = DashboardLabFixtures.contents
        for id in DashboardModuleID.allCases {
            #expect(fixtures.has(id), "\(id.rawValue)")
        }
    }

    @Test("宽度样品落在自己声明的档里")
    func labWidthSamplesMatchBuckets() {
        for sample in DashboardLabWidthSample.allCases {
            #expect(ModuleWidth.bucket(forContentWidth: sample.contentWidth) == sample.width)
            #expect(sample.outerWidth == sample.contentWidth + MeterSpacing.md * 2)
            #expect(sample.outerHeight == MeterSpacing.dashboardTileHeight)
        }
        #expect(
            ModuleWidth.bucket(forContentWidth: DashboardLabWidthSample.listContentWidth) == .regular
        )
    }

    @Test("实验室不再量窗口给模块回填")
    func labDoesNotMeasureModules() throws {
        for name in [
            "DeveloperDashboardLabView.swift",
            "DeveloperDashboardLabModuleView.swift",
            "DeveloperDashboardLabSamples.swift",
            "DashboardLabWidthSample.swift",
        ] {
            let text = try GuardrailSourceScan.sourceText(named: name)
            #expect(!text.contains("onGeometryChange"), "\(name)")
            #expect(!text.contains("GeometryReader"), "\(name)")
            #expect(!text.contains("DashboardLabBento"), "\(name)")
        }
    }

    @Test("设置栈能推到每一块模块")
    func labSettingsRegistersModulePages() throws {
        let text = try GuardrailSourceScan.sourceText(named: "DeveloperSettingsDestinations.swift")
        #expect(text.contains("DashboardModuleID.self"))
        #expect(text.contains("DeveloperDashboardLabModuleView"))
    }

    @Test("实验室设计稿不写真实 store")
    func labFixturesDoNotWriteStore() {
        let model = DashboardModel.preview
        let snapshotsBefore = model.debugReadingCount
        let subscriptionsBefore = model.subscriptions.count
        let totalBefore = model.monthToDate?.totalUSD
        let persistenceBefore = model.persistenceToken

        #expect(DashboardLabFixtures.contents.has(.monthToDate))
        #expect(DashboardLabFixtures.contents.servicesContent?.items.count ?? 0 >= 5)

        #expect(model.debugReadingCount == snapshotsBefore)
        #expect(model.subscriptions.count == subscriptionsBefore)
        #expect(model.monthToDate?.totalUSD == totalBefore)
        #expect(model.persistenceToken == persistenceBefore)
    }
}
#endif
