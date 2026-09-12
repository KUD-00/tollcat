import Foundation
import SwiftData
import Testing
import MeterCore
@testable import MeterPersistence

@MainActor
struct AppPreferencesRecordTests {
    @Test("空库读出默认偏好：AWS 不进全局刷新，演示模式关")
    func emptyStoreReturnsDefaults() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let preferences = try AppPreferencesRecord.load(from: ModelContext(container))

        #expect(preferences == .default)
        #expect(preferences.includeAWSInGlobalRefresh == false)
        #expect(preferences.isDemoModeEnabled == false)
        #expect(preferences.isDemoBannerDismissed == false)
        #expect(preferences.isReminderEnabled == false)
        #expect(preferences.reminderSchedule == .default)
        #expect(preferences.appearance == .system)
        #expect(preferences.hasCompletedOnboarding == false)
        #expect(preferences.providerHistoryRange == .days30)
        #expect(preferences.hidesCat == false)
        #expect(preferences.refreshesUsageOnActivate == false)
        #expect(preferences.displayCurrency == ExchangeRates.usdCode)
        // 新用户默认只看从量；`.unfiltered` 是计算层语义，不是产品默认。
        #expect(preferences.dashboardFilter == DashboardFilter(includesSubscriptions: false))
        #expect(preferences.seenUsageGuideIDs.isEmpty)
        // 菜单栏默认只露猫：金额点开才看得到。
        #expect(preferences.menuBarStyle == .cat)
        #expect(preferences.hidesDockIconWhenWindowClosed == false)
    }

    @Test("关窗后只留菜单栏重开还在")
    func hidesDockIconWhenWindowClosedRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(AppPreferences(hidesDockIconWhenWindowClosed: true), to: context)
        #expect(try AppPreferencesRecord.load(from: context).hidesDockIconWhenWindowClosed)
    }

    @Test("菜单栏露什么重开还在，认不出的旧值退回只露猫")
    func menuBarStyleRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(AppPreferences(menuBarStyle: .catAndAmount), to: context)
        #expect(try AppPreferencesRecord.load(from: context).menuBarStyle == .catAndAmount)

        try AppPreferencesRecord.save(AppPreferences(menuBarStyle: .amount), to: context)
        #expect(try AppPreferencesRecord.load(from: context).menuBarStyle == .amount)

        #expect(AppPreferencesRecord(domain: .default).menuBarStyleRaw == "cat")
        let record = AppPreferencesRecord(domain: .default)
        record.menuBarStyleRaw = "someday-removed-style"
        #expect(record.toDomain().menuBarStyle == .cat)
    }

    @Test("看过的利用指南重开还在，顺序不影响落盘")
    func seenUsageGuideIDsRoundTripSortedUnique() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(
            AppPreferences(seenUsageGuideIDs: ["widgetOnLockScreen", "heroExcludesSubscriptions", "heroExcludesSubscriptions"]),
            to: context
        )
        let loaded = try AppPreferencesRecord.load(from: context)
        #expect(loaded.seenUsageGuideIDs == ["heroExcludesSubscriptions", "widgetOnLockScreen"])
    }

    @Test("展示货币重开还在")
    func displayCurrencyRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(AppPreferences(displayCurrency: "cny"), to: context)
        let loaded = try AppPreferencesRecord.load(from: context)
        #expect(loaded.displayCurrency == "CNY")
    }

    @Test("取景框三维重开都还在")
    func dashboardFilterRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let filter = DashboardFilter(
            monthsBack: 3,
            includesSubscriptions: false,
            excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon)]
        )
        try AppPreferencesRecord.save(
            AppPreferences(dashboardFilter: filter),
            to: ModelContext(container)
        )
        let loaded = try AppPreferencesRecord.load(from: ModelContext(container))
        #expect(loaded.dashboardFilter == filter)
        #expect(loaded.dashboardFilter.excludedAccounts == [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon)])
    }

    @Test("排除名单落盘是排序后的——同一份筛选每次字节相同")
    func excludedAccountsEncodeDeterministically() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)

        try AppPreferencesRecord.save(
            AppPreferences(dashboardFilter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .neon), AccountID.fixture(for: .aws)])),
            to: context
        )
        let first = try #require(
            try context.fetch(FetchDescriptor<AppPreferencesRecord>()).first
        ).filterExcludedAccountsJSON

        try AppPreferencesRecord.save(
            AppPreferences(dashboardFilter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws), AccountID.fixture(for: .neon)])),
            to: context
        )
        let second = try #require(
            try context.fetch(FetchDescriptor<AppPreferencesRecord>()).first
        ).filterExcludedAccountsJSON

        #expect(first == second)
    }

    @Test("清掉筛选之后落盘也回到干净状态，不留残余 id")
    func clearingTheFilterLeavesNoResidue() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(
            AppPreferences(dashboardFilter: DashboardFilter(excludedAccounts: [AccountID.fixture(for: .aws)])),
            to: context
        )
        try AppPreferencesRecord.save(AppPreferences(dashboardFilter: .unfiltered), to: context)
        let loaded = try AppPreferencesRecord.load(from: ModelContext(container))
        #expect(loaded.dashboardFilter == .unfiltered)
        #expect(loaded.dashboardFilter.excludedAccounts.isEmpty)
    }

    @Test("偏好重开还在")
    func layoutRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let saved = AppPreferences(
            includeAWSInGlobalRefresh: true,
            isDemoModeEnabled: true,
            isDemoBannerDismissed: true,
            isReminderEnabled: true,
            reminderSchedule: ReminderSchedule(
                frequency: .monthly,
                hour: 9,
                minute: 30,
                weekday: 1,
                dayOfMonth: 31
            ),
            hasCompletedOnboarding: true
        )

        try AppPreferencesRecord.save(saved, to: context)
        let loaded = try AppPreferencesRecord.load(from: ModelContext(container))

        #expect(loaded.includeAWSInGlobalRefresh)
        #expect(loaded.isDemoModeEnabled)
        #expect(loaded.isDemoBannerDismissed)
        #expect(loaded.isReminderEnabled)
        #expect(loaded.reminderSchedule.frequency == .monthly)
        #expect(loaded.reminderSchedule.hour == 9)
        #expect(loaded.reminderSchedule.minute == 30)
        #expect(loaded.reminderSchedule.dayOfMonth == 31)
        #expect(loaded.appearance == .system)
        #expect(loaded.hasCompletedOnboarding)
        #expect(loaded.providerHistoryRange == .days30)
    }

    @Test("进入 App 自动刷新开关重开还在")
    func refreshesUsageOnActivateRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(
            AppPreferences(refreshesUsageOnActivate: true),
            to: context
        )
        let loaded = try AppPreferencesRecord.load(from: context)
        #expect(loaded.refreshesUsageOnActivate)
    }

    @Test("关闭猫猫开关重开还在")
    func hidesCatRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(AppPreferences(hidesCat: true), to: context)
        let loaded = try AppPreferencesRecord.load(from: context)
        #expect(loaded.hidesCat)
    }

    @Test("历史范围重开还在")
    func historyRangeRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(
            AppPreferences(providerHistoryRange: .months12),
            to: context
        )
        let loaded = try AppPreferencesRecord.load(from: ModelContext(container))
        #expect(loaded.providerHistoryRange == .months12)
    }

    @Test("外观三档重开还在")
    func appearanceRoundTrips() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        try AppPreferencesRecord.save(AppPreferences(appearance: .dark), to: context)
        let loaded = try AppPreferencesRecord.load(from: ModelContext(container))
        #expect(loaded.appearance == .dark)

        try AppPreferencesRecord.save(AppPreferences(appearance: .light), to: context)
        let light = try AppPreferencesRecord.load(from: ModelContext(container))
        #expect(light.appearance == .light)
    }

    @Test("再次保存覆盖同一行，不会插入第二份")
    func saveReplacesSingleton() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)

        try AppPreferencesRecord.save(
            AppPreferences(includeAWSInGlobalRefresh: true),
            to: context
        )
        try AppPreferencesRecord.save(
            AppPreferences(includeAWSInGlobalRefresh: false),
            to: context
        )

        let records = try context.fetch(FetchDescriptor<AppPreferencesRecord>())
        #expect(records.count == 1)
        #expect(records[0].includeAWSInGlobalRefresh == false)
    }
}

/// 三个 JSON 列的容错：解不出来不许被默认值盖掉，多出来的字段不许让整份失效。
@MainActor
struct AppPreferencesJSONToleranceTests {
    @Test("版式 JSON 坏了：读出默认值撑屏，但一次无关的写偏好不会把坏串盖成默认")
    func undecodableLayoutSurvivesUnrelatedSave() throws {
        let container = try PersistenceContainer.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let record = AppPreferencesRecord()
        record.dashboardLayoutJSON = "{not json"
        context.insert(record)
        try context.save()

        var loaded = try AppPreferencesRecord.load(from: context)
        #expect(loaded.dashboardLayout == .default)
        #expect(record.hasUndecodableJSON)

        // 切个外观：版式没动，坏串必须原样留着——下一版能解它的 App 还能救回来。
        loaded.appearance = .dark
        try AppPreferencesRecord.save(loaded, to: context)
        #expect(record.dashboardLayoutJSON == "{not json")

        // 用户真的编辑了版式，才覆盖。
        loaded.dashboardLayout = DashboardLayout(order: ["composition"])
        try AppPreferencesRecord.save(loaded, to: context)
        #expect(record.dashboardLayoutJSON.contains("composition"))
        #expect(!record.hasUndecodableJSON)
    }

    @Test("未来版本的版式 JSON：多出来的字段和更高的版本号不让已知字段失效")
    func futureLayoutJSONStillDecodesKnownFields() throws {
        let raw = #"{"v":9,"order":["composition","trend"],"somethingNew":{"a":1},"monthlyBudgetUSD":"12.30"}"#
        let layout = try #require(AppPreferencesRecord.decodeLayout(raw))
        #expect(layout.order == ["composition", "trend"])
        #expect(layout.monthlyBudgetUSD == Decimal(string: "12.30"))
    }

    @Test("落盘的版式 JSON 带版本号")
    func layoutJSONCarriesVersion() throws {
        let data = try JSONEncoder().encode(DashboardLayout(order: ["trend"]))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["v"] as? Int == DashboardLayout.codingVersion)
    }
}
