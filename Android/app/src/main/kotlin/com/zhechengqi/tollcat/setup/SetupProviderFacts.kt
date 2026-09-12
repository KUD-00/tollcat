package com.zhechengqi.tollcat.setup

import androidx.annotation.StringRes
import com.zhechengqi.tollcat.CatalogProvider
import com.zhechengqi.tollcat.R

/** 简介页上那些编译期就知道的事实。和 iOS `SetupProviderFacts` 同一口径。 */
object SetupProviderFacts {
    enum class SupportLevel {
        Full,
        Theoretical,
        Inbox,
        Unavailable,
    }

    fun supportLevel(provider: CatalogProvider): SupportLevel {
        if (provider.supportsInbox) return SupportLevel.Inbox
        if (provider.hasLiveFetch && provider.accessStatus == "available") return SupportLevel.Full
        if (provider.hasLiveFetch || provider.accessStatus == "pendingVerification") {
            return SupportLevel.Theoretical
        }
        return SupportLevel.Unavailable
    }

    @StringRes
    fun supportTitleRes(level: SupportLevel): Int = when (level) {
        SupportLevel.Full -> R.string.setup_support_full
        SupportLevel.Theoretical -> R.string.setup_support_theoretical
        SupportLevel.Inbox -> R.string.setup_support_inbox
        SupportLevel.Unavailable -> R.string.setup_support_unavailable
    }

    @StringRes
    fun supportCaptionRes(level: SupportLevel): Int? = when (level) {
        SupportLevel.Full -> null
        SupportLevel.Theoretical -> R.string.setup_support_theoretical_caption
        SupportLevel.Inbox -> R.string.setup_support_inbox_caption
        SupportLevel.Unavailable -> R.string.setup_support_unavailable_caption
    }

    fun supportBars(level: SupportLevel): Int = when (level) {
        SupportLevel.Full -> 3
        SupportLevel.Theoretical -> 2
        SupportLevel.Inbox -> 1
        SupportLevel.Unavailable -> 0
    }

    fun offersSetupFeedback(provider: CatalogProvider): Boolean {
        return provider.accessStatus == "pendingVerification" && !provider.supportsInbox
    }
}
