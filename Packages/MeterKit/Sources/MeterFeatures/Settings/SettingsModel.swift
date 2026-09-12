import Foundation
import Observation
import SwiftData
import MeterCore
import MeterFeedback
import MeterPersistence
import MeterTips

@MainActor
@Observable
public final class SettingsModel {
    var dashboard: DashboardModel
    var persistenceStatus: PersistenceStatus
    let tipModel: TipModel
    var isConfirmingClear = false
    var clearErrorMessage: String?
    var clearSuccessToken = 0
    var isPresentingReminderOptIn = false
    /// 深链要落到设置哪一处。消费掉就置回 nil。
    var pendingSettingsNavigation: SettingsNavigation?
    /// 递增才能在已经停在同一处时再跳一次仍生效。
    var settingsNavigationGeneration = 0
    var inboundTransferURL: URL?
    /// 横屏三栏的选中项。手机栈仍走 `path`，不读这个。
    var selectedPane: SettingsPane?
    /// Mac ⌘,：切到设置这一栏。递增才能在已经停在设置时再按一次仍把窗口唤到前台。
    var revealGeneration = 0

    var reminderIntentEnabled: Bool
    var reminderSchedule: ReminderSchedule
    var appearance: AppearancePreference
    var reminderAuthorization: ReminderAuthorization = .notDetermined
    var hidesCat: Bool
    /// Mac 菜单栏露什么。只有 Mac 壳展示这一行，别的平台留着默认值不动。
    var menuBarStyle: MenuBarStyle
    /// Mac：关掉最后一个窗口后从程序坞收起，只留菜单栏。壳里的 app delegate 读它。
    public private(set) var hidesDockIconWhenWindowClosed: Bool
    /// Mac：开机自启动。系统是唯一真相源，不落盘；进设置页时重读一次。
    var launchesAtLogin = false
    /// 用户在「系统设置 › 登录项」里没放行，开关打不开。
    var loginItemRequiresApproval = false
    var refreshesUsageOnActivate: Bool
    var displayCurrency: String

    private let reminderScheduler: any ReminderScheduling
    private let reminderNow: @MainActor @Sendable () -> Date
    private let reminderCalendar: Calendar
    private let feedbackSubmitter: any FeedbackSubmitting
    private let loginItem: any LoginItemControlling

    public convenience init(dashboard: DashboardModel, persistenceStatus: PersistenceStatus) {
        self.init(
            dashboard: dashboard,
            persistenceStatus: persistenceStatus,
            reminderScheduler: UserNotificationReminderScheduler()
        )
    }

    init(
        dashboard: DashboardModel,
        persistenceStatus: PersistenceStatus,
        tipModel: TipModel? = nil,
        reminderScheduler: any ReminderScheduling = InMemoryReminderScheduler(),
        reminderNow: @escaping @MainActor @Sendable () -> Date = { Date() },
        reminderCalendar: Calendar = .current,
        feedbackSubmitter: (any FeedbackSubmitting)? = nil,
        loginItem: (any LoginItemControlling)? = nil
    ) {
        self.dashboard = dashboard
        self.persistenceStatus = persistenceStatus
        self.tipModel = tipModel ?? TipModel(
            container: dashboard.storeContainer,
            catalog: FeatureLaunchArguments.stubTips ? StubTipCatalog() : StoreKitTipCatalog()
        )
        self.reminderScheduler = reminderScheduler
        self.reminderNow = reminderNow
        self.reminderCalendar = reminderCalendar
        self.feedbackSubmitter = feedbackSubmitter
            ?? (FeatureLaunchArguments.stubFeedback
                ? StubFeedbackSubmitter()
                : LiveFeedback.submitter())
        self.loginItem = loginItem ?? LoginItem.live()
        let stored = Self.loadPreferences(from: dashboard.storeContainer)
        self.reminderIntentEnabled = stored.isReminderEnabled
        self.reminderSchedule = stored.reminderSchedule
        if let raw = FeatureLaunchArguments.appearance,
           let override = AppearancePreference(rawValue: raw) {
            self.appearance = override
        } else {
            self.appearance = stored.appearance
        }
        self.hidesCat = FeatureLaunchArguments.hidesCat || stored.hidesCat
        self.menuBarStyle = FeatureLaunchArguments.menuBarStyle
            .flatMap(MenuBarStyle.init(rawValue:)) ?? stored.menuBarStyle
        self.hidesDockIconWhenWindowClosed = stored.hidesDockIconWhenWindowClosed
        self.refreshesUsageOnActivate = stored.refreshesUsageOnActivate
        if let raw = FeatureLaunchArguments.displayCurrency {
            self.displayCurrency = raw
        } else {
            self.displayCurrency = stored.displayCurrency
        }
        refreshLoginItemStatus()
    }

    func refreshLoginItemStatus() {
        launchesAtLogin = loginItem.isEnabled
        loginItemRequiresApproval = loginItem.requiresApproval
    }

    /// 注册失败（沙盒拒绝、系统没放行）时开关回到系统真值，不假装开了。
    func setLaunchesAtLogin(_ enabled: Bool) {
        try? loginItem.setEnabled(enabled)
        refreshLoginItemStatus()
    }

    func setHidesDockIconWhenWindowClosed(_ hidden: Bool) {
        hidesDockIconWhenWindowClosed = hidden
        var preferences = Self.loadPreferences(from: dashboard.storeContainer)
        preferences.hidesDockIconWhenWindowClosed = hidden
        let context = ModelContext(dashboard.storeContainer)
        try? AppPreferencesRecord.save(preferences, to: context)
    }

    func setHidesCat(_ hidden: Bool) {
        hidesCat = hidden
        dashboard.shell.setHidesCat(hidden)
    }

    func setRefreshesUsageOnActivate(_ enabled: Bool) {
        refreshesUsageOnActivate = enabled
        dashboard.setRefreshesUsageOnActivate(enabled)
    }

    func setMenuBarStyle(_ style: MenuBarStyle) {
        menuBarStyle = style
        dashboard.shell.setMenuBarStyle(style)
    }

    var availableDisplayCurrencies: [String] {
        var codes = dashboard.availableDisplayCurrencies
        let current = ExchangeRates.normalized(displayCurrency)
        if !codes.contains(current) {
            codes.insert(current, at: 0)
        }
        return codes
    }

    func setDisplayCurrency(_ code: String) {
        displayCurrency = ExchangeRates.normalized(code)
        dashboard.setDisplayCurrency(displayCurrency)
    }

    var isReminderToggleOn: Bool {
        reminderIntentEnabled && reminderAuthorization.isAuthorized
    }

    var showsNotificationDenied: Bool {
        reminderAuthorization == .denied
    }

    var showsReminderEditors: Bool {
        isReminderToggleOn
    }

    var reminderCalendarForPicker: Calendar {
        reminderCalendar
    }

    /// 每次进反馈页都新建一个：上一次写了一半的内容不该在下一次冒出来。
    func makeFeedbackModel() -> FeedbackModel {
        FeedbackModel(
            submitter: feedbackSubmitter,
            connectedProviderNames: FeedbackModel.connectedNames(dashboard: dashboard)
        )
    }

    /// 用户可见版本号 `X.Y.Z`。更新说明抽屉拿它和「看到哪一版」比大小，
    /// 所以不带 build 号——build 是 CI run number，每次都变。
    var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    var versionCaption: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }

    func setAppearance(_ value: AppearancePreference) {
        appearance = value
        var preferences = Self.loadPreferences(from: dashboard.storeContainer)
        preferences.appearance = value
        let context = ModelContext(dashboard.storeContainer)
        try? AppPreferencesRecord.save(preferences, to: context)
    }

    func confirmClearAllData() {
        do {
            try dashboard.clearAllData()
            persistenceStatus.containsDemoData = false
            persistenceStatus.isDemoBannerDismissed = false
            clearErrorMessage = nil
            clearSuccessToken += 1
            reminderIntentEnabled = false
            reminderSchedule = .default
            appearance = .system
            hidesCat = false
            menuBarStyle = .default
            hidesDockIconWhenWindowClosed = false
            refreshesUsageOnActivate = false
            displayCurrency = ExchangeRates.usdCode
            Task { await reminderScheduler.cancelAll() }
        } catch {
            clearErrorMessage = String(localized: L("没能清干净，请再试一次"))
        }
    }

    func presentImport(url: URL) {
        inboundTransferURL = url
        present(.importExport)
    }

    /// 切到设置。`route` 有值就推进那一页；提醒、外观都在列表第一屏，传 nil。
    func present(_ route: SettingsRoute?) {
        presentNavigation(route.map { .route($0) } ?? .root)
    }

    func presentNavigation(_ navigation: SettingsNavigation) {
        pendingSettingsNavigation = navigation
        settingsNavigationGeneration += 1
        revealGeneration += 1
    }

    func consumePendingSettingsNavigation() -> SettingsNavigation? {
        let navigation = pendingSettingsNavigation
        pendingSettingsNavigation = nil
        return navigation
    }

    func requestReveal() {
        revealGeneration += 1
    }

    func consumeReveal() -> Bool {
        guard revealGeneration > 0 else { return false }
        revealGeneration = 0
        return true
    }

    func handleTransferImported() {
        let stored = Self.loadPreferences(from: dashboard.storeContainer)
        appearance = stored.appearance
        reminderIntentEnabled = stored.isReminderEnabled
        reminderSchedule = stored.reminderSchedule
        hidesCat = stored.hidesCat
        dashboard.shell.setHidesCat(stored.hidesCat)
        menuBarStyle = stored.menuBarStyle
        hidesDockIconWhenWindowClosed = stored.hidesDockIconWhenWindowClosed
        refreshesUsageOnActivate = stored.refreshesUsageOnActivate
        displayCurrency = stored.displayCurrency
        dashboard.reloadMoneyPresentationFromStore()
        persistenceStatus.containsDemoData = dashboard.containsDemoData()
        persistenceStatus.isDemoBannerDismissed = stored.isDemoBannerDismissed
    }

    func dismissDemoBanner() {
        dashboard.dismissDemoBanner()
        persistenceStatus.isDemoBannerDismissed = true
    }

    func refreshReminderAuthorization() async {
        reminderAuthorization = await reminderScheduler.authorizationStatus()
    }

    /// 启动时对齐一次：设置开着但系统里没有待触发的，就重排。
    func alignRemindersOnLaunch() async {
        await refreshReminderAuthorization()
        guard reminderIntentEnabled else { return }
        if reminderAuthorization.isAuthorized {
            let pending = await reminderScheduler.pendingRequestCount()
            let expected = ReminderScheduler.expectedRequestCount(for: reminderSchedule.frequency)
            if pending != expected {
                await rescheduleIfNeeded()
            }
        } else {
            await reminderScheduler.cancelAll()
        }
    }

    func scheduleDebugReminder(in seconds: Int) async {
        let fire = reminderNow().addingTimeInterval(TimeInterval(seconds))
        let components = reminderCalendar.dateComponents([.hour, .minute], from: fire)
        reminderSchedule = ReminderSchedule(
            frequency: .daily,
            hour: components.hour ?? 21,
            minute: components.minute ?? 0,
            weekday: reminderSchedule.weekday,
            dayOfMonth: reminderSchedule.dayOfMonth
        )
        persistReminder()
        await setReminderEnabled(true)
    }

    func setReminderEnabled(_ enabled: Bool) async {
        if enabled {
            if reminderAuthorization == .notDetermined {
                await refreshReminderAuthorization()
            }
            if reminderAuthorization == .notDetermined {
                isPresentingReminderOptIn = true
                return
            }
            await enableRemindersAfterAuthorization()
        } else {
            reminderIntentEnabled = false
            persistReminder()
            await reminderScheduler.cancelAll()
        }
    }

    func confirmReminderOptIn() async {
        isPresentingReminderOptIn = false
        await enableRemindersAfterAuthorization()
    }

    func cancelReminderOptIn() {
        isPresentingReminderOptIn = false
    }

    private func enableRemindersAfterAuthorization() async {
        if reminderAuthorization == .notDetermined {
            let granted = await reminderScheduler.requestAuthorization()
            reminderAuthorization = granted ? .authorized : .denied
        } else {
            await refreshReminderAuthorization()
        }
        guard reminderAuthorization.isAuthorized else {
            reminderIntentEnabled = false
            persistReminder()
            await reminderScheduler.cancelAll()
            return
        }
        reminderIntentEnabled = true
        persistReminder()
        await rescheduleIfNeeded()
    }

    func setReminderFrequency(_ frequency: ReminderFrequency) async {
        reminderSchedule.frequency = frequency
        persistReminder()
        await rescheduleIfNeeded()
    }

    func setReminderTime(hour: Int, minute: Int) async {
        reminderSchedule = ReminderSchedule(
            frequency: reminderSchedule.frequency,
            hour: hour,
            minute: minute,
            weekday: reminderSchedule.weekday,
            dayOfMonth: reminderSchedule.dayOfMonth
        )
        persistReminder()
        await rescheduleIfNeeded()
    }

    func setReminderWeekday(_ weekday: Int) async {
        reminderSchedule = ReminderSchedule(
            frequency: reminderSchedule.frequency,
            hour: reminderSchedule.hour,
            minute: reminderSchedule.minute,
            weekday: weekday,
            dayOfMonth: reminderSchedule.dayOfMonth
        )
        persistReminder()
        await rescheduleIfNeeded()
    }

    func setReminderDayOfMonth(_ day: Int) async {
        reminderSchedule = ReminderSchedule(
            frequency: reminderSchedule.frequency,
            hour: reminderSchedule.hour,
            minute: reminderSchedule.minute,
            weekday: reminderSchedule.weekday,
            dayOfMonth: day
        )
        persistReminder()
        await rescheduleIfNeeded()
    }

    private func rescheduleIfNeeded() async {
        guard reminderIntentEnabled else {
            await reminderScheduler.cancelAll()
            return
        }
        await refreshReminderAuthorization()
        guard reminderAuthorization.isAuthorized else {
            await reminderScheduler.cancelAll()
            return
        }
        let now = reminderNow()
        let specs = ReminderScheduler.triggerSpecs(
            schedule: reminderSchedule,
            now: now,
            calendar: reminderCalendar
        )
        let content = ReminderNotificationCopy.content(
            lastRefreshAt: dashboard.ledger.lastRefreshAt,
            now: now,
            calendar: reminderCalendar
        )
        try? await reminderScheduler.replacePending(specs: specs, content: content)
    }

    private func persistReminder() {
        var preferences = Self.loadPreferences(from: dashboard.storeContainer)
        preferences.isReminderEnabled = reminderIntentEnabled
        preferences.reminderSchedule = reminderSchedule
        let context = ModelContext(dashboard.storeContainer)
        try? AppPreferencesRecord.save(preferences, to: context)
    }

    private static func loadPreferences(from container: ModelContainer) -> AppPreferences {
        (try? AppPreferencesRecord.load(from: ModelContext(container))) ?? .default
    }

    static var preview: SettingsModel {
        SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: InMemoryReminderScheduler()
        )
    }

    static var previewEmpty: SettingsModel {
        SettingsModel(
            dashboard: .previewEmpty,
            persistenceStatus: .preview,
            reminderScheduler: InMemoryReminderScheduler()
        )
    }

    static var previewDenied: SettingsModel {
        SettingsModel(
            dashboard: .preview,
            persistenceStatus: .preview,
            reminderScheduler: InMemoryReminderScheduler(status: .denied)
        )
    }

}
