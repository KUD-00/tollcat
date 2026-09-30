package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.PersistenceNoticeList
import com.zhechengqi.tollcat.ui.PersistenceStatus

private val SectionPadding = Modifier.padding(horizontal = 12.dp)

/**
 * 有数据时的仪表盘（画布 H1 × A）：品牌色顶栏 → 内容纸（需要注意 → 构成粗条 → 近几个月 →
 * 其余开着的模块）。需要注意紧贴在顶栏下面，不参与排序；构成和近几个月是固定槽位；
 * 其余模块按编辑面里的顺序往下排。主页暂时不放猫。
 *
 * [onHeroBehindStatusBar] 报告顶栏此刻是否还垫在状态栏底下——宿主据此切状态栏图标的深浅。
 */
@Composable
fun DashboardPopulatedView(
    dashboard: DashboardSnapshot,
    filter: DashboardFilterState,
    accounts: List<DashboardFilterAccount>,
    onOpenComposition: () -> Unit,
    onOpenComparison: () -> Unit,
    onOpenProvider: (String) -> Unit,
    modifier: Modifier = Modifier,
    onOpenHeatmap: () -> Unit = {},
    onOpenCategories: () -> Unit = {},
    onOpenSubscriptions: () -> Unit = {},
    extraModules: Set<String> = emptySet(),
    moduleOrder: List<String> = emptyList(),
    nowMillis: Long = System.currentTimeMillis(),
    includesSubscriptions: Boolean = filter.includesSubscriptions,
    onToggleSubscriptions: ((Boolean) -> Unit)? = null,
    onFilter: (() -> Unit)? = null,
    onShare: (() -> Unit)? = null,
    isRefreshing: Boolean = false,
    persistenceStatus: PersistenceStatus = PersistenceStatus(),
    onDismissDemo: (() -> Unit)? = null,
    refreshFailed: Boolean = false,
    scrollState: ScrollState = rememberScrollState(),
    onHeroBehindStatusBar: (Boolean) -> Unit = {},
) {
    val order = DashboardModules.resolvedOrder(moduleOrder, extraModules)
    val hero = dashboardHeroState(
        dashboard = dashboard,
        filterNote = dashboard.filterNote,
        includesSubscriptions = includesSubscriptions,
        canToggleScope = onToggleSubscriptions != null,
        nowMillis = nowMillis,
    )

    var heroHeight by remember { mutableIntStateOf(0) }
    val statusBar = WindowInsets.statusBars.getTop(LocalDensity.current)
    val overlap = with(LocalDensity.current) { DashboardSheetOverlap.roundToPx() }
    LaunchedEffect(scrollState, heroHeight, statusBar) {
        snapshotFlow { heroHeight == 0 || scrollState.value < heroHeight - overlap - statusBar }
            .collect(onHeroBehindStatusBar)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(scrollState),
    ) {
        DashboardHeroHeader(
            state = hero,
            filterActive = filter.isActive,
            isRefreshing = isRefreshing,
            onFilter = onFilter,
            onShare = onShare,
            onToggleSubscriptions = onToggleSubscriptions,
            modifier = Modifier.onSizeChanged { heroHeight = it.height },
        )
        DashboardSheet {
            PersistenceNoticeList(
                status = persistenceStatus,
                onDismissDemo = onDismissDemo,
                modifier = SectionPadding,
            )
            DashboardModuleStack(
                dashboard = dashboard,
                order = order,
                onOpenComposition = onOpenComposition,
                onOpenComparison = onOpenComparison,
                onOpenProvider = onOpenProvider,
                onOpenHeatmap = onOpenHeatmap,
                onOpenCategories = onOpenCategories,
                onOpenSubscriptions = onOpenSubscriptions,
                itemModifier = SectionPadding,
            )
            if (refreshFailed) {
                Text(
                    text = stringResource(R.string.dashboard_refresh_failed),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(horizontal = 20.dp),
                )
            }
            // 给右下角的 FAB 让出位置，最后一张卡不被它压住。
            Spacer(Modifier.height(112.dp))
        }
    }
}

@Preview(name = "Light", showBackground = true, heightDp = 1400)
@Preview(name = "Dark", showBackground = true, heightDp = 1400, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardPopulatedViewPreview() {
    TollCatTheme {
        DashboardPopulatedView(
            dashboard = DashboardPreviewData.snapshot.copy(
                subscriptionCaption = "（订阅 $4.00）",
                subscriptionAmountText = "$4.00",
                showsSubscriptionScope = true,
            ),
            filter = DashboardFilterState(includesSubscriptions = true),
            accounts = emptyList(),
            onOpenComposition = {},
            onOpenComparison = {},
            onOpenProvider = {},
            onToggleSubscriptions = {},
            onFilter = {},
            onShare = {},
            refreshFailed = true,
        )
    }
}
