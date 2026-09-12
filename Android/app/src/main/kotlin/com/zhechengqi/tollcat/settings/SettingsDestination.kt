package com.zhechengqi.tollcat.settings

import androidx.compose.runtime.saveable.listSaver

sealed interface SettingsDestination {
    data object Root : SettingsDestination
    // 打赏：Play Billing，对 iOS StoreKit 那三档。
    data object Tip : SettingsDestination
    data object Appearance : SettingsDestination
    data object Currency : SettingsDestination
    data object RefreshOnActivate : SettingsDestination
    data object UsageGuides : SettingsDestination
    data class UsageGuideArticle(val id: String) : SettingsDestination
    data object WhatsNew : SettingsDestination
    data class WhatsNewEntryPage(val version: String) : SettingsDestination
    data object Reminders : SettingsDestination
    data object Inbox : SettingsDestination
    data object Transfer : SettingsDestination
    data object Feedback : SettingsDestination
    data object About : SettingsDestination
    data object Developer : SettingsDestination
    data object DeveloperClock : SettingsDestination
    data object DeveloperData : SettingsDestination
    data object DeveloperLog : SettingsDestination
    data object DeveloperBuild : SettingsDestination
    data object DeveloperWhatsNew : SettingsDestination
    data object Gallery : SettingsDestination
    data class GalleryItem(val id: String) : SettingsDestination
    data object DashboardLab : SettingsDestination
    data class DashboardLabModule(val id: String) : SettingsDestination

    fun encode(): String {
        return when (this) {
            Root -> "root"
            Tip -> "tip"
            Appearance -> "appearance"
            Currency -> "currency"
            RefreshOnActivate -> "refresh"
            UsageGuides -> "guides"
            is UsageGuideArticle -> "guide:$id"
            WhatsNew -> "whats-new"
            is WhatsNewEntryPage -> "whats-new:$version"
            Reminders -> "reminders"
            Inbox -> "inbox"
            Transfer -> "transfer"
            Feedback -> "feedback"
            About -> "about"
            Developer -> "developer"
            DeveloperClock -> "dev-clock"
            DeveloperData -> "dev-data"
            DeveloperLog -> "dev-log"
            DeveloperBuild -> "dev-build"
            DeveloperWhatsNew -> "dev-whats-new"
            Gallery -> "gallery"
            is GalleryItem -> "gallery:$id"
            DashboardLab -> "dev-lab"
            is DashboardLabModule -> "dev-lab:$id"
        }
    }

    companion object {
        val Saver = listSaver<List<SettingsDestination>, String>(
            save = { stack -> stack.map { it.encode() } },
            restore = { encoded ->
                encoded.map(::decode).ifEmpty { listOf(Root) }
            },
        )

        fun decode(raw: String): SettingsDestination {
            return when {
                raw.startsWith("guide:") -> UsageGuideArticle(raw.removePrefix("guide:"))
                raw.startsWith("whats-new:") -> WhatsNewEntryPage(raw.removePrefix("whats-new:"))
                raw == "whats-new" -> WhatsNew
                raw == "tip" -> Tip
                raw == "appearance" -> Appearance
                raw == "currency" -> Currency
                raw == "refresh" -> RefreshOnActivate
                raw == "guides" -> UsageGuides
                raw == "reminders" -> Reminders
                raw == "inbox" -> Inbox
                raw == "transfer" -> Transfer
                raw == "feedback" -> Feedback
                raw == "about" -> About
                raw == "developer" -> Developer
                raw == "dev-clock" -> DeveloperClock
                raw == "dev-data" -> DeveloperData
                raw == "dev-log" -> DeveloperLog
                raw == "dev-build" -> DeveloperBuild
                raw == "dev-whats-new" -> DeveloperWhatsNew
                raw == "gallery" -> Gallery
                raw.startsWith("gallery:") -> GalleryItem(raw.removePrefix("gallery:"))
                raw == "dev-lab" -> DashboardLab
                raw.startsWith("dev-lab:") -> DashboardLabModule(raw.removePrefix("dev-lab:"))
                else -> Root
            }
        }
    }
}
