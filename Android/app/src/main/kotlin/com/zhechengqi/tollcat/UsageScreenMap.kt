package com.zhechengqi.tollcat

import com.zhechengqi.tollcat.dashboard.DashboardRoute
import com.zhechengqi.tollcat.settings.SettingsDestination

fun dashboardUsageScreen(route: DashboardRoute): String {
    return when (route) {
        DashboardRoute.Home -> UsageScreens.DASHBOARD
        DashboardRoute.Composition -> UsageScreens.DASHBOARD_COMPOSITION
        DashboardRoute.Comparison -> UsageScreens.DASHBOARD_COMPARISON
        DashboardRoute.Heatmap,
        DashboardRoute.Categories,
        DashboardRoute.Subscriptions,
        -> UsageScreens.DASHBOARD
    }
}

fun servicesUsageScreen(route: ServicesRoute): String {
    return when (route) {
        ServicesRoute.List -> UsageScreens.SERVICES
        ServicesRoute.Add,
        ServicesRoute.AddMore -> UsageScreens.SERVICES_ADD
        // 历史是服务页的一个子列表，不是单独一步漏斗，不另开一个屏幕名。
        ServicesRoute.Past -> UsageScreens.SERVICES
        is ServicesRoute.Detail -> UsageScreens.SERVICES_DETAIL
        is ServicesRoute.Setup -> UsageScreens.SERVICES_SETUP
    }
}

fun settingsUsageScreen(dest: SettingsDestination): String? {
    return when (dest) {
        SettingsDestination.Root -> UsageScreens.SETTINGS
        SettingsDestination.Tip -> UsageScreens.SETTINGS_TIP
        SettingsDestination.Appearance -> UsageScreens.SETTINGS_APPEARANCE
        SettingsDestination.Currency -> UsageScreens.SETTINGS_CURRENCY
        SettingsDestination.RefreshOnActivate -> UsageScreens.SETTINGS_REFRESH
        SettingsDestination.UsageGuides -> UsageScreens.SETTINGS_USAGE_GUIDES
        is SettingsDestination.UsageGuideArticle -> UsageScreens.SETTINGS_USAGE_GUIDE
        SettingsDestination.WhatsNew,
        is SettingsDestination.WhatsNewEntryPage -> UsageScreens.SETTINGS_WHATS_NEW
        SettingsDestination.Reminders -> UsageScreens.SETTINGS_REMINDERS
        SettingsDestination.Inbox -> UsageScreens.SETTINGS_INBOX
        SettingsDestination.Transfer -> UsageScreens.SETTINGS_IMPORT_EXPORT
        SettingsDestination.Feedback -> UsageScreens.SETTINGS_FEEDBACK
        SettingsDestination.About -> UsageScreens.SETTINGS_ABOUT
        SettingsDestination.Developer,
        SettingsDestination.DeveloperClock,
        SettingsDestination.DeveloperData,
        SettingsDestination.DeveloperLog,
        SettingsDestination.DeveloperBuild,
        SettingsDestination.DeveloperWhatsNew,
        SettingsDestination.Gallery,
        is SettingsDestination.GalleryItem,
        SettingsDestination.DashboardLab,
        is SettingsDestination.DashboardLabModule,
        -> null
    }
}
