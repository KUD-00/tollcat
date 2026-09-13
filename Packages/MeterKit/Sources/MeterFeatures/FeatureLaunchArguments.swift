import Foundation
import MeterCore
import MeterPersistence
import MeterProviders

/// 模拟器截图和 UI 验收用的启动参数。
/// App target 的组装层也从这里读，不要在别处再写一遍字面量。
///
/// ## Release 里这些 flag 一个都不认
///
/// 「正式使用不会带这些 flag」曾经只是句期望：读的是 `ProcessInfo.arguments`，
/// 而 Mac 是直发的——`open -a TollCat --args -meter-refresh-bump` 就能让每次刷新
/// 给金额加一笔假的增量，`-stub-inbox` 能让读数信箱不打真 Worker，
/// `-open-developer` 能在正式包里推出开发页。
///
/// 这些钩子存在的理由全部是「在模拟器上验收」，而截图脚本和 maestro 冒烟
/// **全都是 Debug 构建**（`capture-*.sh` / `maestro-smoke.sh` 里的 `-configuration Debug`）。
/// 所以正式包里直接当作没有参数：判据只有这一处，下面几十个开关不必各自防一遍。
public enum FeatureLaunchArguments {
    public static var arguments: [String] {
        #if DEBUG
        ProcessInfo.processInfo.arguments
        #else
        []
        #endif
    }

    static var openAddProvider: Bool {
        arguments.contains("-open-add-provider")
    }

    static var appearance: String? {
        value(after: "-appearance=")
    }

    /// 验收用：目录不走网络，只用打包副本。
    public static var stubCatalog: Bool {
        arguments.contains("-stub-catalog")
    }

    /// 商店截图用：演示种子读哪一套 fixture。中国区那一趟带 `-demo-fixtures=cn`
    /// ——那套图里不能出现 OpenAI / ChatGPT，见 `FixtureOverlay`。
    /// 上面那条规矩在这里同样成立：Release 里 `arguments` 是空的，所以正式包
    /// 永远读默认那份，不存在「用户装到手机上却看见 cn 那套演示数据」。
    static var demoFixtureOverlay: FixtureOverlay? {
        value(after: "-demo-fixtures=").flatMap(FixtureOverlay.init(rawValue:))
    }

    /// 验收用：读数信箱走 stub，不打真 Worker。
    public static var stubInbox: Bool {
        arguments.contains("-stub-inbox")
    }

    /// Debug 构建一律不发匿名页面计数：本机点来点去会把生产表打脏。
    /// 截图脚本仍传 `-stub-usage-analytics`；Release 里 `arguments` 本来就是空的。
    public static var stubUsageAnalytics: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// 验收用：每次刷新给金额加一笔固定增量，好看出「刷新真的发生了」。
    public static var meterRefreshBump: Bool {
        arguments.contains("-meter-refresh-bump")
    }

    static var displayCurrency: String? {
        value(after: "-display-currency=").map(ExchangeRates.normalized)
    }

    static var openManualSubscription: Bool {
        arguments.contains("-open-manual-subscription")
    }

    static var openSetup: ProviderID? {
        value(after: "-open-setup=").map(ProviderID.init(rawValue:))
    }

    static var openSetupCredentials: Bool {
        arguments.contains("-open-setup-credentials")
    }

    static var openProviderDetail: ProviderID? {
        value(after: "-open-provider-detail=").map(ProviderID.init(rawValue:))
    }

    static var historyRange: ProviderHistoryRange? {
        value(after: "-history-range=").flatMap(ProviderHistoryRange.init(rawValue:))
    }

    static var addSearch: String? {
        value(after: "-add-search=")
    }

    static var setupOutcome: String? {
        value(after: "-setup-outcome=")
    }

    static var dashboardTabSymbol: String? {
        value(after: "-tab-icon=")
    }

    static var openDeveloper: Bool {
        arguments.contains("-open-developer")
    }

    static var openGalleryItem: String? {
        value(after: "-open-gallery=")
    }

    static var clockPreset: String? {
        value(after: "-clock-preset=")
    }

    /// 截图和验收：种子写入、折算都用设计稿那一天，不要跟着模拟器墙钟走。
    public static var usesDesignClock: Bool {
        clockPreset == "design"
    }

    static var openDeveloperTool: String? {
        value(after: "-open-developer-tool=")
    }

    static var openTip: Bool {
        arguments.contains("-open-tip")
    }

    static var openOnboarding: Bool {
        arguments.contains("-open-onboarding")
    }

    static var skipOnboarding: Bool {
        arguments.contains("-skip-onboarding")
    }

    static var openInbox: Bool {
        arguments.contains("-open-inbox")
    }

    static var openFeedback: Bool {
        arguments.contains("-open-feedback")
    }

    /// 模拟器上截图和验收用：走 stub，不要真往 Worker 发一条测试反馈。
    static var stubFeedback: Bool {
        arguments.contains("-stub-feedback")
    }

    /// 同上，打赏那一页：档位走罐装的三档，不去问 App Store。
    /// simctl 装起来的 App 拿不到 scheme 上那份 StoreKit 配置，不给这一条只剩空态。
    static var stubTips: Bool {
        arguments.contains("-stub-tips")
    }

    static var openFilter: Bool {
        arguments.contains("-open-filter")
    }

    /// 和 `-open-filter` 同族：直接打开「编辑仪表盘」那一面。
    static var openDashboardEdit: Bool {
        arguments.contains("-open-dashboard-edit")
    }

    /// 截图 / UI 冒烟用：`-dashboard-modules=composition,services,heatmap` 直接把版式设成这几块
    /// （不含本月合计，它永远在），`-sidebar-module=subscriptions` 钉一块到侧栏。只改内存里的
    /// 版式，不落盘，退出就没了。
    static var dashboardModules: [String]? {
        value(after: "-dashboard-modules=")?.split(separator: ",").map(String.init)
    }

    static var sidebarModule: String? {
        value(after: "-sidebar-module=")
    }

    /// 截图用：把接入列表里前 n 家钉进「我的服务」。这一块的内容来自钉选，
    /// 演示种子一家都没钉，不给这个值的话它渲出来是「这一块暂时没有数据」。
    static var pinnedAccountCount: Int? {
        value(after: "-pin-accounts=").flatMap(Int.init)
    }

    /// 截图用：给「预算线」一个月预算（USD）。同理——不设预算这一块就没有内容。
    static var monthlyBudgetUSD: Decimal? {
        value(after: "-monthly-budget=").flatMap { Decimal(string: $0) }
    }

    /// 和 `-open-inbox` / `-open-about` 同一族的常驻验收钩子。
    /// 分享卡是唯一会把数字送到别人手机上的界面，得能在模拟器上直接看。
    static var openShare: Bool {
        arguments.contains("-open-share")
    }

    /// 验收用：仪表构成页从右侧推进。
    static var openCompositionDetail: Bool {
        arguments.contains("-open-composition-detail")
    }

    /// 验收用：仪表较上月同期详情从右侧推进。
    static var openComparisonDetail: Bool {
        arguments.contains("-open-comparison-detail")
    }

    /// 验收用：详情页「花在哪了」全屏从右侧推进。配合 `-open-provider-detail=` 用。
    static var openSpendBreakdown: Bool {
        arguments.contains("-open-spend-breakdown")
    }

    // 下面三个只给原始值（Int / [String] / Bool），不在这里拼取景框那个类型：
    // 有一条测试按文件名锁死谁能碰它，一个调试钩子不值得把那份名单放宽。
    // 拼装在 `DashboardModel.applyLaunchArgumentFilterIfNeeded()` 里做。
    //
    // 连这段注释都不能写出那个类型名——那条检查是纯文本扫描，注释也算。
    static var filterMonthsBack: Int? {
        value(after: "-filter-months-back=").flatMap(Int.init)
    }

    static var filterExcludedProviderKeys: [String] {
        guard let raw = value(after: "-filter-exclude=") else { return [] }
        return raw.split(separator: ",").map(String.init).filter { !$0.isEmpty }
    }

    static var filterDropsSubscriptions: Bool {
        arguments.contains("-filter-no-subscriptions")
    }

    static var catMood: String? {
        value(after: "-cat-mood=")
    }

    /// 截图用：仪表不画猫。和设置里「打开猫猫」关着是同一件事。
    static var hidesCat: Bool {
        arguments.contains("-hide-cat")
    }

    /// 截图用：钉死 Mac 菜单栏露什么。值是 `MenuBarStyle` 的 rawValue（cat / catAndAmount / amount）。
    static var menuBarStyle: String? {
        value(after: "-menu-bar-style=")
    }

    /// 验收 / 截图用：钉死仪表猫的落点，不要随机。
    static var catPerch: String? {
        value(after: "-cat-perch=")
    }

    static var onboardingPage: OnboardingPage {
        OnboardingPage.fromLaunchArgument(value(after: "-onboarding-page="))
    }

    static var openAbout: Bool {
        arguments.contains("-open-about")
    }

    static var openUsageGuides: Bool {
        arguments.contains("-open-usage-guides")
    }

    static var openUsageGuideDrawer: UsageGuideID? {
        value(after: "-open-usage-guide=").flatMap(UsageGuideID.init(rawValue:))
    }

    /// 更新说明的全量列表（设置 → 更新说明）。
    static var openWhatsNew: Bool {
        arguments.contains("-open-whats-new")
    }

    /// 强制弹更新说明抽屉。截图和演示用——正常路径要真更新过才会弹，
    /// 而模拟器上的库永远是新装的。
    static var openWhatsNewDrawer: Bool {
        arguments.contains("-open-whats-new-drawer")
    }

    /// 截图和跳到某一屏的验收钩子不要被未读指南挡住。
    /// `-open-usage-guide=` 是反例：那就是要弹这篇。
    static var skipUsageGuideDrawer: Bool {
        if arguments.contains("-skip-usage-guide") { return true }
        if openUsageGuideDrawer != nil { return false }
        return skipOnboarding
            || arguments.contains(DemoSeedPolicy.seedArgument)
            || startTab != nil
            || openAbout
            || openTip
            || openInbox
            || openFeedback
            || openTransferExport
            || openTransferImport
            || openDeveloper
            || openGalleryItem != nil
            || openDeveloperTool != nil
            || openAddProvider
            || openManualSubscription
            || openSetup != nil
            || openProviderDetail != nil
            || openFilter
            || openDashboardEdit
            || openShare
            || openCompositionDetail
            || openComparisonDetail
            || openSpendBreakdown
            || openOnboarding
            || openUsageGuides
            || openWhatsNew
            || openWhatsNewDrawer
    }

    /// 启动直接落在某个 tab。`-start-on-settings` / `-start-on-services` 的唯一解析点。
    /// iOS 26 玻璃 tab bar 在模拟器 AX 树里没有单独的「服务」按钮，所以验收得靠它。
    static var startTab: AppTab? {
        if arguments.contains("-start-on-settings") || openUsageGuides || openWhatsNew || openTip {
            return .settings
        }
        if arguments.contains("-start-on-services") {
            return .services
        }
        return nil
    }

    static var openTransferExport: Bool {
        arguments.contains("-open-transfer-export")
    }

    static var openTransferImport: Bool {
        arguments.contains("-open-transfer-import")
    }

    static var transferImportBanner: String? {
        value(after: "-transfer-import-banner=")
    }

    /// 截图用：把每一格小组件渲成 PNG 落到沙盒的 Documents/widget-tiles/，
    /// 给商店宣传图的主屏 mock-up 当素材（主屏上的 widget 截不到，见
    /// `DeveloperWidgetTileDump`）。
    static var dumpsWidgetTiles: Bool {
        arguments.contains("-dump-widget-tiles")
    }

    /// 验收用：启动后把提醒排到这么多秒之后（每天、日历 trigger）。
    static var scheduleReminderInSeconds: Int? {
        value(after: "-schedule-reminder-in=").flatMap(Int.init)
    }

    private static func value(after prefix: String) -> String? {
        guard let raw = arguments.first(where: { $0.hasPrefix(prefix) }) else { return nil }
        let value = String(raw.dropFirst(prefix.count))
        return value.isEmpty ? nil : value
    }
}
