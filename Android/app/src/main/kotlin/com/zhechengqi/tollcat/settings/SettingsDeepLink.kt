package com.zhechengqi.tollcat.settings

import android.net.Uri

/**
 * `tollcat://settings/…`：从通知、别的页面跳进设置某一项。
 *
 * scheme 和仪表深链共用，host 分开。认不出来的路径只打开设置列表。
 */
data class SettingsDeepLinkEvent(val path: String?, val id: Long)

object SettingsDeepLink {
    const val SCHEME = "tollcat"
    const val HOST = "settings"

    fun matches(uri: Uri): Boolean {
        return uri.scheme.equals(SCHEME, ignoreCase = true) &&
            uri.host.equals(HOST, ignoreCase = true)
    }

    fun path(uri: Uri): String? {
        return uri.pathSegments.firstOrNull()?.takeIf { it.isNotBlank() }
    }

    fun destination(path: String?): SettingsDestination {
        return when (path) {
            null, "", "reminders" -> SettingsDestination.Root
            "tip" -> SettingsDestination.Tip
            "inbox" -> SettingsDestination.Inbox
            "import", "transfer" -> SettingsDestination.Transfer
            "feedback" -> SettingsDestination.Feedback
            "about" -> SettingsDestination.About
            "whats-new" -> SettingsDestination.WhatsNew
            else -> SettingsDestination.Root
        }
    }

    fun stack(path: String?): List<SettingsDestination> {
        val dest = destination(path)
        return if (dest == SettingsDestination.Root) {
            listOf(SettingsDestination.Root)
        } else {
            listOf(SettingsDestination.Root, dest)
        }
    }
}
