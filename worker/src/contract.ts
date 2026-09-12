// GENERATED — 由 scripts/generate-shared.py 从 shared/api-contract.json 生成。
// 不要手改：改 shared/api-contract.json 后重跑生成器。


/** 字段上限与类别枚举，和 Swift 客户端、site 表单同一份。 */
export const TIP_NAME_MAX = 40;
export const TIP_MESSAGE_MAX = 500;
export const FEEDBACK_MESSAGE_MAX = 2000;
export const FEEDBACK_CONTACT_MAX = 120;
export const FEEDBACK_PROVIDERS_MAX = 400;
export const FEEDBACK_EXCHANGE_MAX = 1200;
export const FEEDBACK_VERSION_MAX = 40;
export const FEEDBACK_LOCALE_MAX = 40;
export const FEEDBACK_DEVICE_MAX = 40;
export const FEEDBACK_CATEGORIES = new Set(["bug", "idea", "provider", "other"]);
export const USAGE_VERSION_MAX = 40;
export const USAGE_SCREENS_MAX = 32;
export const USAGE_COUNT_MAX = 1000;
export const USAGE_PLATFORMS = new Set(["ios", "android", "macos", "windows"]);
export const USAGE_SCREENS = new Set(["onboarding", "dashboard", "dashboard_composition", "dashboard_comparison", "dashboard_account", "services", "services_add", "services_detail", "services_setup", "services_subscription", "settings", "settings_usage_guides", "settings_usage_guide", "settings_appearance", "settings_currency", "settings_refresh", "settings_reminders", "settings_inbox", "settings_import_export", "settings_feedback", "settings_about", "settings_whats_new", "settings_tip", "share"]);
