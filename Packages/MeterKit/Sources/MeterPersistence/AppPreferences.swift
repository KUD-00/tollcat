import Foundation
import MeterCore

/// 设置页落盘的那一小撮偏好。
public struct AppPreferences: Equatable, Sendable {
    public var includeAWSInGlobalRefresh: Bool
    public var isDemoModeEnabled: Bool
    public var isDemoBannerDismissed: Bool
    public var isReminderEnabled: Bool
    public var reminderSchedule: ReminderSchedule
    /// 设置里的外观。默认暗色。
    public var appearance: AppearancePreference
    public var hasCompletedOnboarding: Bool
    public var providerHistoryRange: ProviderHistoryRange
    /// 仪表上的猫。默认关；打开才出现。
    public var hidesCat: Bool
    /// 每次进入 App（冷启动 / 从后台回前台）自动走一次全局刷新。默认关。
    public var refreshesUsageOnActivate: Bool
    /// 仪表盘的取景框。**只影响仪表盘和分享卡**，Widget 和提醒都不看它。
    ///
    /// 落盘是有意的：筛完退出再进来还在，否则每次都要重设一遍。代价是
    /// 「打开 App 看到一个筛过的数字」，所以首屏必须一直挂着那条限定语——
    /// 见 `MonthToDateModuleContent.filterNote`。
    public var dashboardFilter: DashboardFilter
    /// 展示货币。账本仍是美元，这一项只决定怎么写成字。
    ///
    /// ISO 4217 大写。旧库没有这一列时当成美元。
    public var displayCurrency: String
    /// 已经看过的利用指南 id。新篇用新 id，没在这份名单里就会在冷启动弹一次。
    ///
    /// 排序后落盘，同一份已读每次字节相同。旧库没有这一列时当成一篇都没看过。
    public var seenUsageGuideIDs: [String]
    /// Mac 菜单栏露什么。默认只露猫。旧库没有这一列时也是只露猫。
    /// 不进迁移包：菜单栏是这台 Mac 的事，iPhone / Android 没有对应物。
    public var menuBarStyle: MenuBarStyle
    /// Mac：关掉最后一个窗口后从程序坞收起，只留菜单栏，进程继续跑。默认关。
    /// 不进迁移包，理由同上。
    public var hidesDockIconWhenWindowClosed: Bool
    /// 仪表盘版式：开着哪些模块、顺序、钉出的账号、预算。默认 = 没编辑过。
    /// 进迁移包：换机器不该把摆好的仪表盘摆回默认。
    public var dashboardLayout: DashboardLayout
    /// 更新说明抽屉「看到哪一版」。空串 = 还没记过（首装），那次冷启动不弹、静默推到当前版本。
    ///
    /// 语义是「这一版的打断机会用掉了」，不是「读过了」：弹没弹都推进，只前进不后退。
    /// 进迁移包，和 `seenUsageGuideIDs` 一致——换机器不该把说明再看一遍。
    public var lastSeenWhatsNewVersion: String

    public init(
        includeAWSInGlobalRefresh: Bool = false,
        isDemoModeEnabled: Bool = false,
        isDemoBannerDismissed: Bool = false,
        isReminderEnabled: Bool = false,
        reminderSchedule: ReminderSchedule = .default,
        appearance: AppearancePreference = .default,
        hasCompletedOnboarding: Bool = false,
        providerHistoryRange: ProviderHistoryRange = .default,
        hidesCat: Bool = true,
        refreshesUsageOnActivate: Bool = false,
        // 新用户默认只看从量。`.unfiltered` 是计算层的「什么都不筛」，
        // 语义上仍含订阅；产品默认是另一件事，落在这儿。
        dashboardFilter: DashboardFilter = DashboardFilter(includesSubscriptions: false),
        displayCurrency: String = ExchangeRates.usdCode,
        seenUsageGuideIDs: [String] = [],
        menuBarStyle: MenuBarStyle = .default,
        hidesDockIconWhenWindowClosed: Bool = false,
        dashboardLayout: DashboardLayout = .default,
        lastSeenWhatsNewVersion: String = ""
    ) {
        self.includeAWSInGlobalRefresh = includeAWSInGlobalRefresh
        self.isDemoModeEnabled = isDemoModeEnabled
        self.isDemoBannerDismissed = isDemoBannerDismissed
        self.isReminderEnabled = isReminderEnabled
        self.reminderSchedule = reminderSchedule
        self.appearance = appearance
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.providerHistoryRange = providerHistoryRange
        self.hidesCat = hidesCat
        self.refreshesUsageOnActivate = refreshesUsageOnActivate
        self.dashboardFilter = dashboardFilter
        self.displayCurrency = ExchangeRates.normalized(displayCurrency)
        self.seenUsageGuideIDs = Self.normalizedGuideIDs(seenUsageGuideIDs)
        self.menuBarStyle = menuBarStyle
        self.hidesDockIconWhenWindowClosed = hidesDockIconWhenWindowClosed
        self.dashboardLayout = dashboardLayout
        self.lastSeenWhatsNewVersion = lastSeenWhatsNewVersion
    }

    public static func normalizedGuideIDs(_ ids: [String]) -> [String] {
        Array(Set(ids.filter { !$0.isEmpty })).sorted()
    }

    public static let `default` = AppPreferences()
}
