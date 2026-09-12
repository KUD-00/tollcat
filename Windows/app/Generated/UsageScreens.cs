// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。


namespace TollCat;

/// <summary>允许上报的页面。不在这份名单里的，客户端不发、服务端丢弃。</summary>
internal static class UsageScreens
{
    public const string Onboarding = "onboarding";
    public const string Dashboard = "dashboard";
    public const string DashboardComposition = "dashboard_composition";
    public const string DashboardComparison = "dashboard_comparison";
    public const string DashboardAccount = "dashboard_account";
    public const string Services = "services";
    public const string ServicesAdd = "services_add";
    public const string ServicesDetail = "services_detail";
    public const string ServicesSetup = "services_setup";
    public const string ServicesSubscription = "services_subscription";
    public const string Settings = "settings";
    public const string SettingsUsageGuides = "settings_usage_guides";
    public const string SettingsUsageGuide = "settings_usage_guide";
    public const string SettingsAppearance = "settings_appearance";
    public const string SettingsCurrency = "settings_currency";
    public const string SettingsRefresh = "settings_refresh";
    public const string SettingsReminders = "settings_reminders";
    public const string SettingsInbox = "settings_inbox";
    public const string SettingsImportExport = "settings_import_export";
    public const string SettingsFeedback = "settings_feedback";
    public const string SettingsAbout = "settings_about";
    public const string SettingsWhatsNew = "settings_whats_new";
    public const string SettingsTip = "settings_tip";
    public const string Share = "share";

    public static readonly HashSet<string> All = new()
    {
        Onboarding,
        Dashboard,
        DashboardComposition,
        DashboardComparison,
        DashboardAccount,
        Services,
        ServicesAdd,
        ServicesDetail,
        ServicesSetup,
        ServicesSubscription,
        Settings,
        SettingsUsageGuides,
        SettingsUsageGuide,
        SettingsAppearance,
        SettingsCurrency,
        SettingsRefresh,
        SettingsReminders,
        SettingsInbox,
        SettingsImportExport,
        SettingsFeedback,
        SettingsAbout,
        SettingsWhatsNew,
        SettingsTip,
        Share,
    };
}
