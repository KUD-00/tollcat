package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.R

enum class DashboardModuleID {
    MonthToDate,
    Composition,
    Anomaly,
    BalanceAlert,
    UpcomingCharges,
    FreeQuota,
    MonthlyHighlights,
    ;

    val isPinned: Boolean get() = this == MonthToDate
}

/** 和 iOS `DashboardModuleID.rawValue` 同一组 id。版式只存字符串。 */
object DashboardModules {
    const val COMPOSITION = "composition"
    const val ANOMALY = "anomaly"
    const val BALANCE = "balanceAlert"
    const val UPCOMING = "upcomingCharges"
    const val QUOTA = "freeQuota"
    const val SERVICES = "services"
    const val SUBSCRIPTIONS = "subscriptions"
    const val HEATMAP = "heatmap"
    const val CATEGORIES = "categories"
    const val SUPERLATIVES = "superlatives"
    const val BUDGET = "budget"

    val defaultOn: List<String> = listOf(COMPOSITION, ANOMALY, BALANCE, QUOTA)

    val extras: Set<String> = setOf(
        SERVICES,
        SUBSCRIPTIONS,
        HEATMAP,
        CATEGORIES,
        SUPERLATIVES,
        BUDGET,
    )

    /** 即将扣款已下架，旧版式里存着也不再出现在编辑面。 */
    val retired: Set<String> = setOf(UPCOMING)

    val editable: List<String> = (defaultOn + extras.toList()).filter { it !in retired }

    val attention: Set<String> = setOf(ANOMALY, BALANCE, UPCOMING, QUOTA)

    val fixedSlot: Set<String> = setOf(COMPOSITION)

    fun titleRes(id: String): Int = when (id) {
        COMPOSITION -> R.string.module_composition
        ANOMALY -> R.string.module_anomaly
        BALANCE -> R.string.module_balance
        UPCOMING -> R.string.module_upcoming
        QUOTA -> R.string.module_quota
        SERVICES -> R.string.module_pinned
        SUBSCRIPTIONS -> R.string.module_subscriptions
        HEATMAP -> R.string.module_heatmap
        CATEGORIES -> R.string.module_categories
        SUPERLATIVES -> R.string.module_superlatives
        BUDGET -> R.string.module_budget
        else -> R.string.dashboard_edit
    }

    fun summaryRes(id: String): Int = when (id) {
        COMPOSITION -> R.string.module_composition_summary
        ANOMALY -> R.string.module_anomaly_summary
        BALANCE -> R.string.module_balance_summary
        UPCOMING -> R.string.module_upcoming_summary
        QUOTA -> R.string.module_quota_summary
        SERVICES -> R.string.module_pinned_summary
        SUBSCRIPTIONS -> R.string.module_subscriptions_summary
        HEATMAP -> R.string.module_heatmap_summary
        CATEGORIES -> R.string.module_categories_summary
        SUPERLATIVES -> R.string.module_superlatives_summary
        BUDGET -> R.string.module_budget_summary
        else -> R.string.dashboard_edit_reorder
    }

    fun normalized(order: List<String>): List<String> {
        val allowed = (editable + extras).toSet() - retired
        val seen = LinkedHashSet<String>()
        order.forEach { id -> if (id in allowed) seen.add(id) }
        val list = seen.toList()
        return list.filter { it in fixedSlot } + list.filter { it !in fixedSlot }
    }
}
