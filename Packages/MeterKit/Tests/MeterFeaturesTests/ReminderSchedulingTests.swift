import Foundation
import SwiftData
import Testing
import UserNotifications
import MeterCore
import MeterPersistence
@testable import MeterFeatures

@MainActor
struct ReminderSchedulingTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("通知文案不含金额、百分比、provider 名")
    func copyHasNoAmountsOrProviders() {
        let now = date(2026, 8, 16, 12)
        let content = ReminderNotificationCopy.content(
            lastRefreshAt: date(2026, 8, 13, 12),
            now: now,
            calendar: calendar
        )

        #expect(content.title == String(localized: L("该看一眼了")))
        #expect(content.body.contains(String(localized: L("打开 App，看看这个月花了多少。"))))
        #expect(content.body.contains(String(localized: L("上次刷新 \(3) 天前。"))))
        assertSafeCopy(content.title)
        assertSafeCopy(content.body)
    }

    @Test("拒绝授权时开关回到关闭态，不排通知")
    func deniedKeepsToggleOff() async {
        let scheduler = InMemoryReminderScheduler(status: .notDetermined, grantOnRequest: false)
        let model = SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { Date() },
            reminderCalendar: calendar
        )

        await model.setReminderEnabled(true)
        #expect(model.isPresentingReminderOptIn)
        #expect(model.isReminderToggleOn == false)
        #expect(await scheduler.requestCount == 0)

        await model.confirmReminderOptIn()

        #expect(model.isReminderToggleOn == false)
        #expect(model.reminderIntentEnabled == false)
        #expect(model.showsNotificationDenied)
        #expect(await scheduler.pendingRequestCount() == 0)
        #expect(await scheduler.requestCount == 1)
    }

    @Test("未决定时打开开关先出预授权，不立刻要系统权限")
    func notDeterminedPresentsOptInBeforeSystemPrompt() async {
        let scheduler = InMemoryReminderScheduler(status: .notDetermined, grantOnRequest: true)
        let model = SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { Date() },
            reminderCalendar: calendar
        )

        await model.setReminderEnabled(true)
        #expect(model.isPresentingReminderOptIn)
        #expect(model.isReminderToggleOn == false)
        #expect(await scheduler.requestCount == 0)
        #expect(await scheduler.pendingRequestCount() == 0)

        await model.confirmReminderOptIn()
        #expect(!model.isPresentingReminderOptIn)
        #expect(model.isReminderToggleOn)
        #expect(await scheduler.requestCount == 1)
        #expect(await scheduler.pendingRequestCount() == ReminderScheduler.expectedRequestCount(for: .daily))
    }

    @Test("预授权关掉就保持关，不弹系统框")
    func decliningOptInDoesNotRequestAuthorization() async {
        let scheduler = InMemoryReminderScheduler(status: .notDetermined, grantOnRequest: true)
        let model = SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { Date() },
            reminderCalendar: calendar
        )

        await model.setReminderEnabled(true)
        model.cancelReminderOptIn()

        #expect(!model.isPresentingReminderOptIn)
        #expect(model.isReminderToggleOn == false)
        #expect(model.reminderAuthorization == .notDetermined)
        #expect(await scheduler.requestCount == 0)
        #expect(await scheduler.pendingRequestCount() == 0)
    }

    @Test("系统已经拒绝时打开开关不会请求成功")
    func alreadyDeniedStaysOff() async {
        let scheduler = InMemoryReminderScheduler(status: .denied)
        let model = SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { Date() },
            reminderCalendar: calendar
        )
        await model.refreshReminderAuthorization()
        #expect(model.showsNotificationDenied)

        await model.setReminderEnabled(true)

        #expect(model.isReminderToggleOn == false)
        #expect(await scheduler.pendingRequestCount() == 0)
    }

    @Test("改三次设置后待触发的通知数量仍然是预期值")
    func replacingScheduleDoesNotAccumulate() async throws {
        let scheduler = InMemoryReminderScheduler(status: .authorized)
        let now = date(2026, 8, 16, 12)
        let model = SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { now },
            reminderCalendar: calendar
        )

        await model.setReminderEnabled(true)
        await model.setReminderFrequency(.daily)
        await model.setReminderFrequency(.weekly)
        await model.setReminderFrequency(.monthly)

        #expect(await scheduler.pendingRequestCount() == ReminderScheduler.expectedRequestCount(for: .monthly))

        await model.setReminderFrequency(.daily)
        #expect(await scheduler.pendingRequestCount() == ReminderScheduler.expectedRequestCount(for: .daily))
        #expect(await scheduler.replaceCount >= 3)

        await model.setReminderEnabled(false)
        #expect(await scheduler.pendingRequestCount() == 0)
    }

    @Test("内存调度器三次替换不累积")
    func inMemoryReplaceDoesNotAccumulate() async throws {
        let scheduler = InMemoryReminderScheduler(status: .authorized)
        let now = date(2026, 8, 16, 12)
        let content = ReminderNotificationCopy.content(
            lastRefreshAt: nil,
            now: now,
            calendar: calendar
        )
        let daily = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .daily, hour: 21, minute: 0),
            now: now,
            calendar: calendar
        )
        let monthly = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .monthly, hour: 21, minute: 0, dayOfMonth: 31),
            now: now,
            calendar: calendar
        )

        try await scheduler.replacePending(specs: daily, content: content)
        try await scheduler.replacePending(specs: monthly, content: content)
        try await scheduler.replacePending(specs: daily, content: content)

        #expect(await scheduler.pendingRequestCount() == 1)
        #expect(await scheduler.replaceCount == 3)
        #expect(await scheduler.lastContent?.body.contains("$") != true)
    }

    @Test("UN 适配只排日历 trigger，标识带固定前缀")
    func userNotificationAdapterUsesCalendarTriggers() async throws {
        let scheduler = UserNotificationReminderScheduler()
        await scheduler.cancelAll()
        let now = Date()
        let wall = Calendar.current
        let content = ReminderNotificationCopy.content(
            lastRefreshAt: now.addingTimeInterval(-3 * 86_400),
            now: now,
            calendar: wall
        )
        let specs = ReminderScheduler.triggerSpecs(
            schedule: ReminderSchedule(frequency: .daily, hour: 21, minute: 0),
            now: now,
            calendar: wall
        )
        #expect(specs.count == 1)
        #expect(specs[0].repeats)
        assertSafeCopy(content.title)
        assertSafeCopy(content.body)

        try await scheduler.replacePending(specs: specs, content: content)
        try await scheduler.replacePending(specs: specs, content: content)
        try await scheduler.replacePending(specs: specs, content: content)

        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let ours = pending.filter { $0.identifier.hasPrefix(UserNotificationReminderScheduler.identifierPrefix) }
        for request in ours {
            assertSafeCopy(request.content.title)
            assertSafeCopy(request.content.body)
            #expect(request.trigger is UNCalendarNotificationTrigger)
        }
        // 测试宿主可能丢掉未授权的 pending；数量不累积由内存调度器覆盖。
        #expect(ours.count <= ReminderScheduler.expectedRequestCount(for: .daily))
        await scheduler.cancelAll()
        #expect(await scheduler.pendingRequestCount() == 0)
    }

    @Test("启动时设置开着但没有待触发的会重排")
    func launchAlignReschedulesMissingRequests() async throws {
        let scheduler = InMemoryReminderScheduler(status: .authorized)
        let dashboard = DashboardModel.preview
        var preferences = AppPreferences()
        preferences.isReminderEnabled = true
        preferences.reminderSchedule = ReminderSchedule(frequency: .weekly, hour: 21, minute: 0)
        try AppPreferencesRecord.save(preferences, to: ModelContext(dashboard.storeContainer))

        let model = SettingsModel(
            dashboard: dashboard,
            persistenceStatus: .preview,
            reminderScheduler: scheduler,
            reminderNow: { date(2026, 8, 16, 12) },
            reminderCalendar: calendar
        )
        #expect(model.reminderIntentEnabled)
        #expect(await scheduler.pendingRequestCount() == 0)

        await model.alignRemindersOnLaunch()
        #expect(await scheduler.pendingRequestCount() == ReminderScheduler.expectedRequestCount(for: .weekly))
    }

    private func assertSafeCopy(_ text: String) {
        #expect(!text.contains("$"))
        #expect(!text.contains("%"))
        #expect(!text.contains("AWS"))
        #expect(!text.contains("OpenAI"))
        #expect(!text.contains("Cloudflare"))
        #expect(!text.contains("GitHub"))
        #expect(!text.contains("Neon"))
        #expect(!text.contains("Vercel"))
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }
}
