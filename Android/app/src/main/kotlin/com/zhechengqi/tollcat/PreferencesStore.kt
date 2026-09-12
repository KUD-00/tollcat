package com.zhechengqi.tollcat

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import com.zhechengqi.tollcat.dashboard.DashboardModules
import com.zhechengqi.tollcat.settings.AppearancePreference
import com.zhechengqi.tollcat.settings.ColorSourcePreference
import com.zhechengqi.tollcat.settings.ReminderFrequency
import org.json.JSONArray

class PreferencesStore(context: Context) {
    internal val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    var displayCurrency: String
        get() = prefs.getString(CURRENCY, "USD") ?: "USD"
        set(value) {
            prefs.edit().putString(CURRENCY, value).apply()
        }

    var appearance: String
        get() = prefs.getString(APPEARANCE, AppearancePreference.DARK) ?: AppearancePreference.DARK
        set(value) {
            prefs.edit().putString(APPEARANCE, AppearancePreference.normalize(value)).apply()
        }

    var colorSource: String
        get() = prefs.getString(COLOR_SOURCE, ColorSourcePreference.DYNAMIC) ?: ColorSourcePreference.DYNAMIC
        set(value) {
            prefs.edit().putString(COLOR_SOURCE, ColorSourcePreference.normalize(value)).apply()
        }

    var refreshOnActivate: Boolean
        get() = prefs.getBoolean(REFRESH_ON_ACTIVATE, false)
        set(value) {
            prefs.edit().putBoolean(REFRESH_ON_ACTIVATE, value).apply()
        }

    var hidesCat: Boolean
        get() = prefs.getBoolean(HIDES_CAT, true)
        set(value) {
            prefs.edit().putBoolean(HIDES_CAT, value).apply()
        }

    var reminderEnabled: Boolean
        get() = prefs.getBoolean(REMINDER_ENABLED, false)
        set(value) {
            prefs.edit().putBoolean(REMINDER_ENABLED, value).apply()
        }

    var reminderFrequency: String
        get() = prefs.getString(REMINDER_FREQUENCY, ReminderFrequency.WEEKLY) ?: ReminderFrequency.WEEKLY
        set(value) {
            prefs.edit().putString(REMINDER_FREQUENCY, ReminderFrequency.normalize(value)).apply()
        }

    var reminderHour: Int
        get() = prefs.getInt(REMINDER_HOUR, 21).coerceIn(0, 23)
        set(value) {
            prefs.edit().putInt(REMINDER_HOUR, value.coerceIn(0, 23)).apply()
        }

    var reminderMinute: Int
        get() = prefs.getInt(REMINDER_MINUTE, 0).coerceIn(0, 59)
        set(value) {
            prefs.edit().putInt(REMINDER_MINUTE, value.coerceIn(0, 59)).apply()
        }

    /** Calendar weekday: 1 = Sunday … 7 = Saturday, same as iOS. */
    var reminderWeekday: Int
        get() = prefs.getInt(REMINDER_WEEKDAY, 2).coerceIn(1, 7)
        set(value) {
            prefs.edit().putInt(REMINDER_WEEKDAY, value.coerceIn(1, 7)).apply()
        }

    var reminderDayOfMonth: Int
        get() = prefs.getInt(REMINDER_DAY, 1).coerceIn(1, 31)
        set(value) {
            prefs.edit().putInt(REMINDER_DAY, value.coerceIn(1, 31)).apply()
        }

    /** 预授权面点过「打开通知」。用来区分还没问过和系统已经拒绝。 */
    var reminderOptInCompleted: Boolean
        get() = prefs.getBoolean(REMINDER_OPT_IN, false)
        set(value) {
            prefs.edit().putBoolean(REMINDER_OPT_IN, value).apply()
        }

    fun seenUsageGuides(): Set<String> {
        return prefs.getStringSet(SEEN_GUIDES, emptySet()) ?: emptySet()
    }

    fun markUsageGuideSeen(id: String) {
        val next = seenUsageGuides() + id
        prefs.edit().putStringSet(SEEN_GUIDES, next).apply()
    }

    fun clearSeenUsageGuides() {
        prefs.edit().remove(SEEN_GUIDES).apply()
    }

    var isDemoModeEnabled: Boolean
        get() = prefs.getBoolean(DEMO_MODE, false)
        set(value) {
            prefs.edit().putBoolean(DEMO_MODE, value).apply()
        }

    /**
     * Light/dark are applied app-wide on API 31+ via [UiModeManager].
     * "System" uses [UiModeManager.MODE_NIGHT_AUTO] — the closest reset without AppCompat.
     */
    fun applyAppearance(context: Context = appContext) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val manager = context.applicationContext.getSystemService(UiModeManager::class.java) ?: return
        val mode = when (appearance) {
            AppearancePreference.LIGHT -> UiModeManager.MODE_NIGHT_NO
            AppearancePreference.DARK -> UiModeManager.MODE_NIGHT_YES
            else -> UiModeManager.MODE_NIGHT_AUTO
        }
        manager.setApplicationNightMode(mode)
    }

    /**
     * 更新说明弹出面「看到哪一版」。空串 = 还没记过（首装）。
     * 语义是「这一版的打断机会用掉了」，不是「读过了」：弹没弹都推进，只前进。
     */
    var lastSeenWhatsNewVersion: String
        get() = prefs.getString(LAST_SEEN_WHATS_NEW, "") ?: ""
        set(value) {
            prefs.edit().putString(LAST_SEEN_WHATS_NEW, value).apply()
        }

    var dashboardFilterJson: String
        get() = prefs.getString(DASHBOARD_FILTER, "") ?: ""
        set(value) {
            prefs.edit().putString(DASHBOARD_FILTER, value).apply()
        }

    fun includeInGlobalRefresh(accountId: String): Boolean {
        return prefs.getStringSet(INCLUDE_PAID_REFRESH, emptySet())?.contains(accountId) == true
    }

    var extraModules: Set<String>
        get() = enabledModuleOrder().filter { it in DashboardModules.extras }.toSet()
        set(value) {
            val core = enabledModuleOrder().filter { it !in DashboardModules.extras }
            setModuleOrder(core + value.filter { it in DashboardModules.extras })
        }

    /**
     * 开着的模块 id，不含本月合计。空串 = 还没编辑过，用产品默认
     * （和 iOS `DashboardLayout.order` 空数组同一口径）。
     */
    fun enabledModuleOrder(): List<String> {
        val raw = prefs.getString(MODULE_ORDER, null)
        if (raw.isNullOrEmpty()) {
            val extras = prefs.getStringSet(EXTRA_MODULES, emptySet()) ?: emptySet()
            return DashboardModules.normalized(
                DashboardModules.defaultOn + extras.filter { it in DashboardModules.extras },
            )
        }
        val stored = runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).map { array.optString(it) }
        }.getOrDefault(emptyList())
        return DashboardModules.normalized(stored)
    }

    fun setModuleOrder(order: List<String>) {
        val normalized = DashboardModules.normalized(order)
        val extras = normalized.filter { it in DashboardModules.extras }.toSet()
        prefs.edit()
            .putString(MODULE_ORDER, JSONArray(normalized).toString())
            .putStringSet(EXTRA_MODULES, extras)
            .apply()
    }

    fun resetModuleLayout() {
        prefs.edit().remove(MODULE_ORDER).putStringSet(EXTRA_MODULES, emptySet()).apply()
    }

    var pinnedAccountIds: Set<String>
        get() = prefs.getStringSet(PINNED_ACCOUNTS, emptySet()) ?: emptySet()
        set(value) {
            prefs.edit().putStringSet(PINNED_ACCOUNTS, value).apply()
        }

    var monthlyBudgetUsd: String
        get() = prefs.getString(MONTHLY_BUDGET, "") ?: ""
        set(value) {
            prefs.edit().putString(MONTHLY_BUDGET, value).apply()
        }

    // 信箱的 mailbox + readKey 已经搬进 AndroidKeystoreCredentialStore（见
    // InboxMailboxStore）。readKey 能读走全部读数、删信箱、再签发投递 key，
    // 不该和外观、预算一起明文躺在这份 XML 里。下面两个只读属性仅供一次性搬迁，
    // 不要新增写入点。
    val legacyInboxMailbox: String
        get() = prefs.getString(INBOX_MAILBOX, "") ?: ""

    val legacyInboxReadKey: String
        get() = prefs.getString(INBOX_READ_KEY, "") ?: ""

    fun clearLegacyInbox() {
        prefs.edit().remove(INBOX_MAILBOX).remove(INBOX_READ_KEY).apply()
    }

    fun setIncludeInGlobalRefresh(accountId: String, include: Boolean) {
        val next = (prefs.getStringSet(INCLUDE_PAID_REFRESH, emptySet()) ?: emptySet()).toMutableSet()
        if (include) next.add(accountId) else next.remove(accountId)
        prefs.edit().putStringSet(INCLUDE_PAID_REFRESH, next).apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
        applyAppearance()
    }

    private companion object {
        const val PREFS = "tollcat.preferences"
        const val CURRENCY = "display_currency"
        const val APPEARANCE = "appearance"
        const val COLOR_SOURCE = "color_source"
        const val REFRESH_ON_ACTIVATE = "refresh_on_activate"
        const val HIDES_CAT = "hides_cat"
        const val REMINDER_ENABLED = "reminder_enabled"
        const val REMINDER_FREQUENCY = "reminder_frequency"
        const val REMINDER_HOUR = "reminder_hour"
        const val REMINDER_MINUTE = "reminder_minute"
        const val REMINDER_WEEKDAY = "reminder_weekday"
        const val REMINDER_DAY = "reminder_day"
        const val REMINDER_OPT_IN = "reminder_opt_in"
        const val SEEN_GUIDES = "seen_usage_guides"
        const val DEMO_MODE = "demo_mode"
        const val LAST_SEEN_WHATS_NEW = "last_seen_whats_new"
        const val DASHBOARD_FILTER = "dashboard_filter"
        const val INCLUDE_PAID_REFRESH = "include_paid_refresh"
        const val EXTRA_MODULES = "extra_modules"
        const val MODULE_ORDER = "module_order"
        const val PINNED_ACCOUNTS = "pinned_accounts"
        const val MONTHLY_BUDGET = "monthly_budget_usd"
        const val INBOX_MAILBOX = "inbox_mailbox"
        const val INBOX_READ_KEY = "inbox_read_key"
    }
}
