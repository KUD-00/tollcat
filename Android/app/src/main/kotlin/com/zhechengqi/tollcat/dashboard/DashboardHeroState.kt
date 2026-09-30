package com.zhechengqi.tollcat.dashboard

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R

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
    return DashboardHeroState(
        periodTitle = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
        // 口径已经在共享层算进去了：切「合计 / 按量」是重算，不是在这里换一个字段。
        amount = dashboard.formattedTotal,
        projected = dashboard.formattedProjected,
        monthProgress = if (dashboard.allowsProjection) MonthProgress.at(nowMillis, locale) else null,
        // 和 iOS 首屏同一条规则：只在算进订阅时出现（金额和条件都由共享层给）。
        // 标签只写「订阅」——多月取景框里这是几个月的合计，不是「本月订阅」。
        subscriptionNote = dashboard.subscriptionAmountText?.let {
            stringResource(R.string.dashboard_subscription_chip, it)
        },
        includesSubscriptions = includesSubscriptions,
        showsScopeToggle = canToggleScope && dashboard.showsSubscriptionScope,
        staleCaption = dashboard.staleCaption,
        filterNote = filterNote,
    )
}
