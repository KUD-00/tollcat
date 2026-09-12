package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.dashboard.DashboardModules

/**
 * 实验室目录跟着生产模块清单走，不另开名单。
 * id 和 iOS `DashboardModuleID.rawValue` / [DashboardModules] 同一组。
 */
object DashboardLabModules {
    const val MONTH_TO_DATE = "monthToDate"

    val defaultOrder: List<String> = listOf(
        MONTH_TO_DATE,
        DashboardModules.COMPOSITION,
        DashboardModules.ANOMALY,
        DashboardModules.BALANCE,
        DashboardModules.UPCOMING,
        DashboardModules.QUOTA,
        DashboardModules.SERVICES,
        DashboardModules.SUBSCRIPTIONS,
        DashboardModules.HEATMAP,
        DashboardModules.CATEGORIES,
        DashboardModules.SUPERLATIVES,
        DashboardModules.BUDGET,
    )

    fun isRetired(id: String): Boolean = id == DashboardModules.UPCOMING

    fun titleRes(id: String): Int = when (id) {
        MONTH_TO_DATE -> R.string.hero_label
        else -> DashboardModules.titleRes(id)
    }

    fun summaryRes(id: String): Int = when (id) {
        MONTH_TO_DATE -> R.string.dev_lab_month_to_date_summary
        else -> DashboardModules.summaryRes(id)
    }

    fun has(snapshot: DashboardSnapshot, id: String): Boolean = when (id) {
        MONTH_TO_DATE -> !snapshot.empty
        DashboardModules.COMPOSITION -> snapshot.composition.isNotEmpty()
        DashboardModules.ANOMALY -> snapshot.anomalies.isNotEmpty()
        DashboardModules.BALANCE -> snapshot.balanceAlerts.isNotEmpty()
        DashboardModules.UPCOMING -> snapshot.upcoming.isNotEmpty()
        DashboardModules.QUOTA -> snapshot.freeQuota.isNotEmpty()
        DashboardModules.SERVICES -> snapshot.pinnedServices.isNotEmpty()
        DashboardModules.SUBSCRIPTIONS -> snapshot.subscriptions?.items?.isNotEmpty() == true
        DashboardModules.HEATMAP -> snapshot.heatmap.isNotEmpty()
        DashboardModules.CATEGORIES -> snapshot.categories.isNotEmpty()
        DashboardModules.SUPERLATIVES -> snapshot.superlatives.isNotEmpty()
        DashboardModules.BUDGET -> snapshot.budget != null
        else -> false
    }
}
