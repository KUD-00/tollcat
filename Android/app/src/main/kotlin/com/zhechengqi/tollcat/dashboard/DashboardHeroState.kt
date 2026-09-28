package com.zhechengqi.tollcat.dashboard

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import com.zhechengqi.tollcat.DashboardSnapshot

/**
 * 仪表盘顶栏要画的一切，已经本地化好。顶栏自己不读快照，
 * 画廊和引导页可以直接拼一份假的。
 */
data class DashboardHeroState(
    val periodTitle: String,
    val amount: String,
    /** 只有当月才有；回看过去的月份为 null，右侧那个数和进度条一起消失。 */
    val projected: String?,
    val monthProgress: MonthProgress?,
    val subscriptionNote: String?,
    val includesSubscriptions: Boolean,
    /** 有订阅才有「合计 / 按量」可切；没有订阅时两个口径是同一个数。 */
    val showsScopeToggle: Boolean,
    val staleCaption: String?,
    val filterNote: String?,
    val currencyNote: String?,
)

@Composable
fun dashboardHeroState(
    dashboard: DashboardSnapshot,
    filterNote: String?,
    includesSubscriptions: Boolean,
    canToggleScope: Boolean,
    nowMillis: Long,
): DashboardHeroState {
    val locale = LocalConfiguration.current.locales[0]
    val amount = if (includesSubscriptions) {
        dashboard.formattedTotal
    } else {
        dashboard.formattedVariable.ifBlank { dashboard.formattedTotal }
    }
    return DashboardHeroState(
        periodTitle = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
        amount = amount,
        projected = dashboard.formattedProjected.takeIf { dashboard.allowsProjection && it.isNotBlank() },
        monthProgress = if (dashboard.allowsProjection) MonthProgress.at(nowMillis, locale) else null,
        subscriptionNote = dashboard.subscriptionCaption,
        includesSubscriptions = includesSubscriptions,
        showsScopeToggle = canToggleScope && !dashboard.subscriptionCaption.isNullOrBlank(),
        staleCaption = dashboard.staleCaption,
        filterNote = filterNote,
        currencyNote = dashboard.currencyNote,
    )
}
