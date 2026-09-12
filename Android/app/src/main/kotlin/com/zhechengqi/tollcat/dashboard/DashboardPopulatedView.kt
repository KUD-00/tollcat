package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.PersistenceNoticeList
import com.zhechengqi.tollcat.ui.PersistenceStatus

@Composable
fun DashboardPopulatedView(
    dashboard: DashboardSnapshot,
    filter: DashboardFilterState,
    accounts: List<DashboardFilterAccount>,
    onOpenComposition: () -> Unit,
    onOpenComparison: () -> Unit,
    onOpenProvider: (String) -> Unit,
    onOpenHeatmap: () -> Unit = {},
    onOpenCategories: () -> Unit = {},
    onOpenSubscriptions: () -> Unit = {},
    extraModules: Set<String> = emptySet(),
    moduleOrder: List<String> = emptyList(),
    modifier: Modifier = Modifier,
    hidesCat: Boolean = false,
    includesSubscriptions: Boolean = filter.includesSubscriptions,
    onToggleSubscriptions: ((Boolean) -> Unit)? = null,
    onSelectSubscription: (() -> Unit)? = null,
    staleCaption: String? = dashboard.staleCaption,
    persistenceStatus: PersistenceStatus = PersistenceStatus(),
    onDismissDemo: (() -> Unit)? = null,
    refreshFailed: Boolean = false,
) {
    // 取景框在共享层生效：这里到手的行已经筛好、标题已经是对应月份。
    val composition = dashboard.composition
    val comparison = ComparisonContent.from(
        dashboard = dashboard,
        currentLabel = stringResource(R.string.dashboard_comparison_this_month),
        previousLabel = stringResource(R.string.dashboard_comparison_last_month),
        unavailableCaption = stringResource(R.string.dashboard_comparison_unavailable),
    )
    // 单个月不成趋势：一根柱会被画成占满整块瓷砖的色块。
    val trend = dashboard.trend.filter { it.fraction > 0f }.takeIf { it.size >= 2 }.orEmpty()
    val mood = DashboardCatMood.from(dashboard)
    val amount = if (includesSubscriptions) {
        dashboard.formattedTotal
    } else {
        dashboard.formattedVariable.ifBlank { dashboard.formattedTotal }
    }
    val subscriptionCaption = dashboard.subscriptionCaption
    val filterNote = dashboardFilterNote(filter, accounts)
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = MeterSpacing.md, vertical = MeterSpacing.xs),
        verticalArrangement = Arrangement.spacedBy(Bento.gap),
    ) {
        PersistenceNoticeList(
            status = persistenceStatus,
            onDismissDemo = onDismissDemo,
            modifier = Modifier.padding(bottom = MeterSpacing.xs),
        )
        MonthToDateModuleView(
            amountText = amount,
            monthTitle = "",
            projectedCaption = if (dashboard.allowsProjection) {
                stringResource(R.string.projected_caption, dashboard.formattedProjected)
            } else {
                null
            },
            subscriptionCaption = subscriptionCaption,
            currencyNote = dashboard.currencyNote,
            filterNote = filterNote,
            shape = Bento.top,
            includesSubscriptions = includesSubscriptions,
            onToggleSubscriptions = onToggleSubscriptions,
            onSelectSubscription = onSelectSubscription,
            staleCaption = staleCaption,
        )
        val order = moduleOrder.ifEmpty {
            DashboardModules.normalized(DashboardModules.defaultOn + extraModules)
        }
        if (DashboardModules.COMPOSITION in order) {
            DashboardCatStage(
                composition = composition,
                comparison = comparison,
                trend = trend,
                mood = mood,
                speech = dashboard.catSpeech,
                onOpenComposition = onOpenComposition,
                onOpenComparison = onOpenComparison,
                showsCat = !hidesCat,
            )
        }
        val slots = buildList<List<String>> {
            val pending = mutableListOf<String>()
            fun flush() {
                if (pending.isEmpty()) return
                add(pending.toList())
                pending.clear()
            }
            order.forEach { id ->
                if (id == DashboardModules.COMPOSITION) return@forEach
                if (id in DashboardModules.attention) {
                    pending.add(id)
                } else {
                    flush()
                    add(listOf(id))
                }
            }
            flush()
        }
        slots.forEach { slot ->
            val first = slot.firstOrNull() ?: return@forEach
            if (first in DashboardModules.attention) {
                DashboardModuleFactory.Attention(
                    dashboard = dashboard,
                    onOpenProvider = onOpenProvider,
                    ids = slot,
                )
            } else {
                when (first) {
                    DashboardModules.SERVICES ->
                        PinnedServicesModuleView(dashboard.pinnedServices, onOpen = onOpenProvider)
                    DashboardModules.SUBSCRIPTIONS ->
                        SubscriptionsModuleCard(dashboard.subscriptions, onOpen = onOpenSubscriptions)
                    DashboardModules.HEATMAP ->
                        HeatmapModuleView(dashboard.heatmap, onOpen = onOpenHeatmap)
                    DashboardModules.CATEGORIES ->
                        CategoriesModuleView(dashboard.categories, onOpen = onOpenCategories)
                    DashboardModules.SUPERLATIVES ->
                        SuperlativesModuleView(dashboard.superlatives, onOpen = onOpenProvider)
                    DashboardModules.BUDGET ->
                        dashboard.budget?.let { BudgetModuleView(it) }
                }
            }
        }
        if (refreshFailed) {
            Text(
                text = stringResource(R.string.dashboard_refresh_failed),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
            )
        }
        Spacer(Modifier.height(MeterSpacing.xxl * 3))
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardPopulatedViewPreview() {
    TollCatTheme {
        DashboardPopulatedView(
            dashboard = DashboardPreviewData.snapshot.copy(
                subscriptionCaption = "本月订阅 $4.00 · 已计入",
                staleCaption = "部分数据陈旧，仍显示上次成功的数字",
            ),
            filter = DashboardFilterState(includesSubscriptions = true),
            accounts = emptyList(),
            onOpenComposition = {},
            onOpenComparison = {},
            onOpenProvider = {},
            includesSubscriptions = true,
            onToggleSubscriptions = {},
            onSelectSubscription = {},
            refreshFailed = true,
        )
    }
}
