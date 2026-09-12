import Foundation

/// 偏好的可移植快照。外观和历史范围用 raw value，好让 Core 不依赖 Persistence 类型。
public struct TransferPreferences: Codable, Equatable, Sendable {
    public var includeAWSInGlobalRefresh: Bool
    public var isReminderEnabled: Bool
    public var reminderSchedule: ReminderSchedule
    public var appearanceRaw: String
    public var hasCompletedOnboarding: Bool
    public var providerHistoryRangeRaw: String
    public var hidesCat: Bool
    public var refreshesUsageOnActivate: Bool
    public var displayCurrency: String
    public var seenUsageGuideIDs: [String]
    /// 仪表盘版式（开着哪些模块、顺序、钉出的账号、预算）。可选：旧包没有这一项，
    /// 读到 nil 落产品默认。钉出的账号引用 `connections` 里搬过去的同一批 AccountID。
    public var dashboardLayout: DashboardLayout?
    /// 更新说明「看到哪一版」。可选：旧包没有这一项，读到 nil 当成还没记过。
    /// 进包的理由和 `seenUsageGuideIDs` 一样——换机器不该把说明再看一遍。
    public var lastSeenWhatsNewVersion: String?

    public init(
        includeAWSInGlobalRefresh: Bool,
        isReminderEnabled: Bool,
        reminderSchedule: ReminderSchedule,
        appearanceRaw: String,
        hasCompletedOnboarding: Bool,
        providerHistoryRangeRaw: String,
        hidesCat: Bool = false,
        refreshesUsageOnActivate: Bool = false,
        displayCurrency: String = ExchangeRates.usdCode,
        seenUsageGuideIDs: [String] = [],
        dashboardLayout: DashboardLayout? = nil,
        lastSeenWhatsNewVersion: String? = nil
    ) {
        self.includeAWSInGlobalRefresh = includeAWSInGlobalRefresh
        self.isReminderEnabled = isReminderEnabled
        self.reminderSchedule = reminderSchedule
        self.appearanceRaw = appearanceRaw
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.providerHistoryRangeRaw = providerHistoryRangeRaw
        self.hidesCat = hidesCat
        self.refreshesUsageOnActivate = refreshesUsageOnActivate
        self.displayCurrency = displayCurrency
        self.seenUsageGuideIDs = seenUsageGuideIDs
        self.dashboardLayout = dashboardLayout
        self.lastSeenWhatsNewVersion = lastSeenWhatsNewVersion
    }
}
