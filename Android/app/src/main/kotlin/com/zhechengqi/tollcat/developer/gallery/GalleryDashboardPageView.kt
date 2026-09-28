package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.DashboardStatusBarAppearance
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.DashboardFabMenu
import com.zhechengqi.tollcat.dashboard.DashboardFabScrim
import com.zhechengqi.tollcat.dashboard.DashboardFilterState
import com.zhechengqi.tollcat.dashboard.DashboardPopulatedView
import com.zhechengqi.tollcat.dashboard.DashboardPreviewData
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/** 画廊里的整页：和主页同一个 DashboardPopulatedView，只是数据用设计稿、状态可以左下角切。 */
private data class PageVariant(val label: String, val dashboard: DashboardSnapshot, val includesSubscriptions: Boolean)

/** 设计稿那一天（2026-08-16）：进度条和「今天」对得上样例数字。 */
private const val DesignClockMillis = 1_786_881_600_000L

private val pageVariants: List<PageVariant> by lazy {
    val base = DashboardPreviewData.snapshot.copy(subscriptionCaption = "本月订阅 $4.00 · 已计入")
    listOf(
        PageVariant("有急事", base, includesSubscriptions = true),
        PageVariant("没急事", base.copy(anomalies = emptyList()), includesSubscriptions = true),
        PageVariant(
            "回看 7 月",
            base.copy(
                monthTitle = "七月",
                periodCaption = "七月",
                allowsProjection = false,
                formattedTotal = "$56.40",
                formattedVariable = "$56.40",
                anomalies = emptyList(),
                balanceAlerts = emptyList(),
                freeQuota = emptyList(),
                formattedComparison = null,
                changePercent = null,
                comparisonPercentText = null,
                comparisonTone = null,
            ),
            includesSubscriptions = true,
        ),
        PageVariant(
            "数据陈旧",
            base.copy(
                formattedVariable = "$43.20",
                formattedProjected = "$83.70",
                subscriptionCaption = "本月订阅 $24.00 · 未计入",
                staleCaption = "部分数据陈旧，仍显示上次成功的数字",
            ),
            includesSubscriptions = false,
        ),
    )
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun GalleryDashboardPageView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    var index by remember { mutableIntStateOf(0) }
    var fabExpanded by remember { mutableStateOf(false) }
    var heroBehindStatusBar by remember { mutableStateOf(true) }
    val variant = pageVariants[index]
    var includesSubscriptions by remember(index) { mutableStateOf(variant.includesSubscriptions) }
    BackHandler(onBack = onBack)
    DashboardStatusBarAppearance(overHero = heroBehindStatusBar)
    Box(modifier.fillMaxSize()) {
        DashboardPopulatedView(
            dashboard = variant.dashboard,
            filter = DashboardFilterState(includesSubscriptions = includesSubscriptions),
            accounts = emptyList(),
            onOpenComposition = {},
            onOpenComparison = {},
            onOpenProvider = {},
            nowMillis = DesignClockMillis,
            includesSubscriptions = includesSubscriptions,
            onToggleSubscriptions = { includesSubscriptions = it },
            onFilter = {},
            onShare = {},
            scrollState = rememberScrollState(),
            onHeroBehindStatusBar = { heroBehindStatusBar = it },
        )
        DashboardFabScrim(expanded = fabExpanded, onDismiss = { fabExpanded = false })
        Surface(
            onClick = { index = (index + 1) % pageVariants.size },
            color = MaterialTheme.colorScheme.inverseSurface,
            contentColor = MaterialTheme.colorScheme.inverseOnSurface,
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .align(Alignment.BottomStart)
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(16.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            ) {
                SymbolIcon(MaterialSymbol.SwapHoriz, contentDescription = null, size = 20.dp)
                Text("${index + 1}/${pageVariants.size} · ${variant.label}", style = MaterialTheme.typography.labelLarge)
            }
        }
        DashboardFabMenu(
            expanded = fabExpanded,
            onExpandedChange = { fabExpanded = it },
            onAddService = {},
            onAddSubscription = {},
            onEditDashboard = {},
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(end = 16.dp, bottom = 16.dp),
        )
    }
}

@Preview(name = "Light", showBackground = true, heightDp = 1200)
@Preview(name = "Dark", showBackground = true, heightDp = 1200, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryDashboardPageViewPreview() {
    TollCatTheme {
        GalleryDashboardPageView(onBack = {})
    }
}
