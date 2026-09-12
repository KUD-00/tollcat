import Foundation
import SwiftData
import MeterCore

/// 整份偏好只存一行。用固定 id 找，避免设置页每次 insert 出第二份。
@Model
public final class AppPreferencesRecord {
    public var id: String
    public var includeAWSInGlobalRefresh: Bool
    public var isDemoModeEnabled: Bool
    public var isDemoBannerDismissed: Bool
    public var isReminderEnabled: Bool = false
    public var reminderFrequencyRaw: String = ReminderFrequency.weekly.rawValue
    public var reminderHour: Int = 21
    public var reminderMinute: Int = 0
    public var reminderWeekday: Int = 2
    public var reminderDayOfMonth: Int = 1
    public var appearanceRaw: String = AppearancePreference.default.rawValue
    public var hasCompletedOnboarding: Bool = false
    public var providerHistoryRangeRaw: String = ProviderHistoryRange.default.rawValue
    public var hidesCat: Bool = true
    /// 默认关——保持「手动刷新」的默认。
    public var refreshesUsageOnActivate: Bool = false
    public var displayCurrencyRaw: String = ExchangeRates.usdCode
    /// 取景框三列。订阅口径默认关——新用户先看纯从量。
    public var filterMonthsBack: Int = 0
    /// 时间那一维的意图（`DashboardPeriod.storageKind`）和区间长度。
    /// 旧库没有这两列，读出来是「单月」——也就是加这个特性之前的行为。
    public var filterPeriodKindRaw: String = "months"
    public var filterPeriodMonthCount: Int = 1
    public var filterIncludesSubscriptions: Bool = false
    /// AccountID 的 UUID 字符串，排序后编码——同一份筛选每次落盘字节相同。
    public var filterExcludedAccountsJSON: String = "[]"
    public var seenUsageGuideIDsJSON: String = "[]"
    /// Mac 菜单栏露什么。默认只露猫。不进迁移包。
    public var menuBarStyleRaw: String = MenuBarStyle.default.rawValue
    /// Mac：关窗后只留菜单栏。默认关。不进迁移包。
    public var hidesDockIconWhenWindowClosed: Bool = false
    /// 仪表盘版式整份 JSON（`DashboardLayout`）。键排序后编码，同一份版式每次落盘字节相同。
    /// 旧库没有这一列 / 解不出来时当成没编辑过。
    public var dashboardLayoutJSON: String = "{}"
    /// 更新说明抽屉「看到哪一版」。旧库没有这一列时是空串，也就是「还没记过」。
    public var lastSeenWhatsNewVersion: String = ""

    public static let singletonID = "meter.app-preferences"

    public init(domain: AppPreferences = .default) {
        self.id = Self.singletonID
        self.includeAWSInGlobalRefresh = domain.includeAWSInGlobalRefresh
        self.isDemoModeEnabled = domain.isDemoModeEnabled
        self.isDemoBannerDismissed = domain.isDemoBannerDismissed
        self.isReminderEnabled = domain.isReminderEnabled
        self.reminderFrequencyRaw = domain.reminderSchedule.frequency.rawValue
        self.reminderHour = domain.reminderSchedule.hour
        self.reminderMinute = domain.reminderSchedule.minute
        self.reminderWeekday = domain.reminderSchedule.weekday
        self.reminderDayOfMonth = domain.reminderSchedule.dayOfMonth
        self.appearanceRaw = domain.appearance.rawValue
        self.hasCompletedOnboarding = domain.hasCompletedOnboarding
        self.providerHistoryRangeRaw = domain.providerHistoryRange.rawValue
        self.hidesCat = domain.hidesCat
        self.refreshesUsageOnActivate = domain.refreshesUsageOnActivate
        self.filterMonthsBack = domain.dashboardFilter.monthsBack
        self.filterPeriodKindRaw = domain.dashboardFilter.period.storageKind
        self.filterPeriodMonthCount = domain.dashboardFilter.period.storageMonthCount
        self.filterIncludesSubscriptions = domain.dashboardFilter.includesSubscriptions
        self.filterExcludedAccountsJSON = Self.encodeAccounts(domain.dashboardFilter.excludedAccounts)
        self.displayCurrencyRaw = domain.displayCurrency
        self.seenUsageGuideIDsJSON = Self.encode(AppPreferences.normalizedGuideIDs(domain.seenUsageGuideIDs))
        self.menuBarStyleRaw = domain.menuBarStyle.rawValue
        self.hidesDockIconWhenWindowClosed = domain.hidesDockIconWhenWindowClosed
        self.dashboardLayoutJSON = Self.encodeLayout(domain.dashboardLayout)
        self.lastSeenWhatsNewVersion = domain.lastSeenWhatsNewVersion
    }

    public func apply(_ domain: AppPreferences) {
        includeAWSInGlobalRefresh = domain.includeAWSInGlobalRefresh
        isDemoModeEnabled = domain.isDemoModeEnabled
        isDemoBannerDismissed = domain.isDemoBannerDismissed
        isReminderEnabled = domain.isReminderEnabled
        reminderFrequencyRaw = domain.reminderSchedule.frequency.rawValue
        reminderHour = domain.reminderSchedule.hour
        reminderMinute = domain.reminderSchedule.minute
        reminderWeekday = domain.reminderSchedule.weekday
        reminderDayOfMonth = domain.reminderSchedule.dayOfMonth
        appearanceRaw = domain.appearance.rawValue
        hasCompletedOnboarding = domain.hasCompletedOnboarding
        providerHistoryRangeRaw = domain.providerHistoryRange.rawValue
        hidesCat = domain.hidesCat
        refreshesUsageOnActivate = domain.refreshesUsageOnActivate
        filterMonthsBack = domain.dashboardFilter.monthsBack
        filterPeriodKindRaw = domain.dashboardFilter.period.storageKind
        filterPeriodMonthCount = domain.dashboardFilter.period.storageMonthCount
        filterIncludesSubscriptions = domain.dashboardFilter.includesSubscriptions
        // 三个 JSON 列：**解不出来的存量不许被默认值盖掉。**
        //
        // `toDomain()` 解不出时给的是默认值，那只是这一趟界面上的兜底；要是紧接着一次
        // 无关的写偏好（比如切个外观）把这个默认值原样写回去，用户排了半年的版式就真没了，
        // 而且没有任何提示。所以：原串解不出、而要写回去的又是默认值，就保留原串——
        // 下一版能解它的 App 还能把它救回来。用户真的改了版式（不再是默认）才覆盖。
        filterExcludedAccountsJSON = Self.preserving(
            filterExcludedAccountsJSON,
            decodes: { Self.decode($0) != nil },
            isDefault: domain.dashboardFilter.excludedAccounts.isEmpty,
            encoded: Self.encodeAccounts(domain.dashboardFilter.excludedAccounts)
        )
        displayCurrencyRaw = domain.displayCurrency
        seenUsageGuideIDsJSON = Self.preserving(
            seenUsageGuideIDsJSON,
            decodes: { Self.decode($0) != nil },
            isDefault: domain.seenUsageGuideIDs.isEmpty,
            encoded: Self.encode(AppPreferences.normalizedGuideIDs(domain.seenUsageGuideIDs))
        )
        menuBarStyleRaw = domain.menuBarStyle.rawValue
        hidesDockIconWhenWindowClosed = domain.hidesDockIconWhenWindowClosed
        dashboardLayoutJSON = Self.preserving(
            dashboardLayoutJSON,
            decodes: { Self.decodeLayout($0) != nil },
            isDefault: domain.dashboardLayout.isDefault,
            encoded: Self.encodeLayout(domain.dashboardLayout)
        )
        lastSeenWhatsNewVersion = domain.lastSeenWhatsNewVersion
    }

    /// 解不出 + 要写的是默认值 → 保留原串；否则写新的。
    private static func preserving(
        _ stored: String,
        decodes: (String) -> Bool,
        isDefault: Bool,
        encoded: String
    ) -> String {
        if isDefault, !decodes(stored) { return stored }
        return encoded
    }

    /// 三个 JSON 列里有没有解不出来的。开发页和读失败提示用它说「有一份偏好读不懂」。
    public var hasUndecodableJSON: Bool {
        Self.decodeLayout(dashboardLayoutJSON) == nil
            || Self.decode(filterExcludedAccountsJSON) == nil
            || Self.decode(seenUsageGuideIDsJSON) == nil
    }

    public func toDomain() -> AppPreferences {
        AppPreferences(
            includeAWSInGlobalRefresh: includeAWSInGlobalRefresh,
            isDemoModeEnabled: isDemoModeEnabled,
            isDemoBannerDismissed: isDemoBannerDismissed,
            isReminderEnabled: isReminderEnabled,
            reminderSchedule: ReminderSchedule(
                frequency: ReminderFrequency(rawValue: reminderFrequencyRaw) ?? .weekly,
                hour: reminderHour,
                minute: reminderMinute,
                weekday: reminderWeekday,
                dayOfMonth: reminderDayOfMonth
            ),
            appearance: AppearancePreference(rawValue: appearanceRaw) ?? .default,
            hasCompletedOnboarding: hasCompletedOnboarding,
            providerHistoryRange: ProviderHistoryRange(rawValue: providerHistoryRangeRaw) ?? .default,
            hidesCat: hidesCat,
            refreshesUsageOnActivate: refreshesUsageOnActivate,
            dashboardFilter: DashboardFilter(
                period: DashboardPeriod.fromStorage(
                    kind: filterPeriodKindRaw,
                    monthsBack: filterMonthsBack,
                    monthCount: filterPeriodMonthCount
                ),
                includesSubscriptions: filterIncludesSubscriptions,
                excludedAccounts: Self.decodeAccounts(filterExcludedAccountsJSON)
            ),
            displayCurrency: displayCurrencyRaw,
            seenUsageGuideIDs: Self.decode(seenUsageGuideIDsJSON) ?? [],
            menuBarStyle: MenuBarStyle(rawValue: menuBarStyleRaw) ?? .default,
            hidesDockIconWhenWindowClosed: hidesDockIconWhenWindowClosed,
            // 解不出来先给默认值撑这一屏；`apply` 那边保证这个默认值不会写回去盖掉原串。
            dashboardLayout: Self.decodeLayout(dashboardLayoutJSON) ?? .default,
            lastSeenWhatsNewVersion: lastSeenWhatsNewVersion
        )
    }

    private static func encodeLayout(_ layout: DashboardLayout) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(layout) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// 解不出回 nil，不回默认值——「没编辑过」和「读不懂」是两件事，`apply` 要分得开。
    static func decodeLayout(_ raw: String) -> DashboardLayout? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DashboardLayout.self, from: data)
    }

    private static func encodeAccounts(_ ids: Set<AccountID>) -> String {
        encode(ids.map { $0.rawValue.uuidString }.sorted())
    }

    private static func decodeAccounts(_ raw: String) -> Set<AccountID> {
        Set((decode(raw) ?? []).compactMap { UUID(uuidString: $0).map(AccountID.init(rawValue:)) })
    }

    public static func load(from context: ModelContext) throws -> AppPreferences {
        try fetch(in: context)?.toDomain() ?? .default
    }

    public static func save(_ preferences: AppPreferences, to context: ModelContext) throws {
        if let existing = try fetch(in: context) {
            existing.apply(preferences)
        } else {
            context.insert(AppPreferencesRecord(domain: preferences))
        }
        try context.save()
    }

    private static func fetch(in context: ModelContext) throws -> AppPreferencesRecord? {
        let target = singletonID
        var descriptor = FetchDescriptor<AppPreferencesRecord>(
            predicate: #Predicate { $0.id == target }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private static func encode(_ values: [String]) -> String {
        guard let data = try? JSONEncoder().encode(values) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// 解不出回 nil——「空名单」和「读不懂」是两件事，`apply` 要分得开。
    private static func decode(_ raw: String) -> [String]? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}
