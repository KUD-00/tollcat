// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。


import Foundation

/// 允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。
/// 名单是产品页面，不是某家服务、不是某个账号。
public enum UsageAnalyticsScreen: String, Hashable, Sendable, Codable, CaseIterable {
    case onboarding = "onboarding"
    case dashboard = "dashboard"
    case dashboardComposition = "dashboard_composition"
    case dashboardComparison = "dashboard_comparison"
    case dashboardAccount = "dashboard_account"
    case services = "services"
    case servicesAdd = "services_add"
    case servicesDetail = "services_detail"
    case servicesSetup = "services_setup"
    case servicesSubscription = "services_subscription"
    case settings = "settings"
    case settingsUsageGuides = "settings_usage_guides"
    case settingsUsageGuide = "settings_usage_guide"
    case settingsAppearance = "settings_appearance"
    case settingsCurrency = "settings_currency"
    case settingsRefresh = "settings_refresh"
    case settingsReminders = "settings_reminders"
    case settingsInbox = "settings_inbox"
    case settingsImportExport = "settings_import_export"
    case settingsFeedback = "settings_feedback"
    case settingsAbout = "settings_about"
    case settingsWhatsNew = "settings_whats_new"
    case settingsTip = "settings_tip"
    case share = "share"
}
