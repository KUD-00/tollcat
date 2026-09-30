package com.zhechengqi.tollcat.dashboard

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.DashboardSnapshot

/**
 * 内容纸上那一摞：需要注意 → 构成粗条 + 近几个月 → 其余开着的模块（按编辑面的顺序）。
 *
 * 仪表盘和分享卡**共用这一份**：用户在编辑面里开了热力图，发出去的图上就该有热力图；
 * 关掉构成，图上也不该有那张粗条卡。分享卡不许另攒一套「精简版仪表盘」——和 iOS
 * `ShareCardModules` 同一条规矩。渲成图时由 `LocalStaticRender` 收掉点得动的装饰。
 */
@Composable
fun DashboardModuleStack(
    dashboard: DashboardSnapshot,
    order: List<String>,
    onOpenComposition: () -> Unit,
    onOpenComparison: () -> Unit,
    onOpenProvider: (String) -> Unit,
    onOpenHeatmap: () -> Unit,
    onOpenCategories: () -> Unit,
    onOpenSubscriptions: () -> Unit,
    itemModifier: Modifier = Modifier,
) {
    val attention = AttentionSummary.from(dashboard, order)
    // 单个月不成趋势：一根柱会被画成占满整块的色块。
    val trend = dashboard.trend.filter { it.fraction > 0f }.takeIf { it.size >= 2 }.orEmpty()
    DashboardAttentionSection(summary = attention, onOpen = onOpenProvider)
    if (DashboardModules.COMPOSITION in order) {
        CompositionBarsCard(
            rows = dashboard.compositionSlices,
            onOpenRow = onOpenProvider,
            onOpenAll = onOpenComposition,
            modifier = itemModifier,
        )
        TrendSummaryCard(points = trend, onOpen = onOpenComparison, modifier = itemModifier)
    }
    order.forEach { id ->
        when (id) {
            DashboardModules.SERVICES ->
                PinnedServicesModuleView(dashboard.pinnedServices, onOpen = onOpenProvider, modifier = itemModifier)
            DashboardModules.SUBSCRIPTIONS ->
                SubscriptionsModuleCard(dashboard.subscriptions, onOpen = onOpenSubscriptions, modifier = itemModifier)
            DashboardModules.HEATMAP ->
                HeatmapModuleView(dashboard.heatmap, onOpen = onOpenHeatmap, modifier = itemModifier)
            DashboardModules.CATEGORIES ->
                CategoriesModuleView(dashboard.categories, onOpen = onOpenCategories, modifier = itemModifier)
            DashboardModules.SUPERLATIVES ->
                SuperlativesModuleView(dashboard.superlatives, onOpen = onOpenProvider, modifier = itemModifier)
            DashboardModules.BUDGET ->
                dashboard.budget?.let { BudgetModuleView(it, modifier = itemModifier) }
        }
    }
}
