// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。


package com.zhechengqi.tollcat

/** 允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。 */
object UsageScreens {
    const val ONBOARDING = "onboarding"
    const val DASHBOARD = "dashboard"
    const val DASHBOARD_COMPOSITION = "dashboard_composition"
    const val DASHBOARD_COMPARISON = "dashboard_comparison"
    const val DASHBOARD_ACCOUNT = "dashboard_account"
    const val SERVICES = "services"
    const val SERVICES_ADD = "services_add"
    const val SERVICES_DETAIL = "services_detail"
    const val SERVICES_SETUP = "services_setup"
    const val SERVICES_SUBSCRIPTION = "services_subscription"
    const val SETTINGS = "settings"
    const val SETTINGS_USAGE_GUIDES = "settings_usage_guides"
    const val SETTINGS_USAGE_GUIDE = "settings_usage_guide"
    const val SETTINGS_APPEARANCE = "settings_appearance"
    const val SETTINGS_CURRENCY = "settings_currency"
    const val SETTINGS_REFRESH = "settings_refresh"
    const val SETTINGS_REMINDERS = "settings_reminders"
    const val SETTINGS_INBOX = "settings_inbox"
    const val SETTINGS_IMPORT_EXPORT = "settings_import_export"
    const val SETTINGS_FEEDBACK = "settings_feedback"
    const val SETTINGS_ABOUT = "settings_about"
    const val SETTINGS_WHATS_NEW = "settings_whats_new"
    const val SETTINGS_TIP = "settings_tip"
    const val SHARE = "share"

    val all: Set<String> = setOf(
        ONBOARDING,
        DASHBOARD,
        DASHBOARD_COMPOSITION,
        DASHBOARD_COMPARISON,
        DASHBOARD_ACCOUNT,
        SERVICES,
        SERVICES_ADD,
        SERVICES_DETAIL,
        SERVICES_SETUP,
        SERVICES_SUBSCRIPTION,
        SETTINGS,
        SETTINGS_USAGE_GUIDES,
        SETTINGS_USAGE_GUIDE,
        SETTINGS_APPEARANCE,
        SETTINGS_CURRENCY,
        SETTINGS_REFRESH,
        SETTINGS_REMINDERS,
        SETTINGS_INBOX,
        SETTINGS_IMPORT_EXPORT,
        SETTINGS_FEEDBACK,
        SETTINGS_ABOUT,
        SETTINGS_WHATS_NEW,
        SETTINGS_TIP,
        SHARE,
    )
}
