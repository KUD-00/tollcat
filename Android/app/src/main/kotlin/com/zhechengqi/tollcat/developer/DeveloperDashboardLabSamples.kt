package com.zhechengqi.tollcat.developer

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.AttentionSummary
import com.zhechengqi.tollcat.dashboard.BudgetModuleView
import com.zhechengqi.tollcat.dashboard.CompositionBarsCard
import com.zhechengqi.tollcat.dashboard.DashboardAttentionSection
import com.zhechengqi.tollcat.dashboard.DashboardHeroHeader
import com.zhechengqi.tollcat.dashboard.dashboardHeroState
import com.zhechengqi.tollcat.dashboard.CategoriesModuleView
import com.zhechengqi.tollcat.dashboard.DashboardModules
import com.zhechengqi.tollcat.dashboard.HeatmapModuleView
import com.zhechengqi.tollcat.dashboard.PinnedServicesModuleView
import com.zhechengqi.tollcat.dashboard.SubscriptionsModuleCard
import com.zhechengqi.tollcat.dashboard.SuperlativesModuleView
import com.zhechengqi.tollcat.ui.Bento

/** 一块模块在各壳里的样子。尺寸全部是常数，不量窗口。 */
@Composable
fun DeveloperDashboardLabSamples(
    id: String,
    dashboard: DashboardSnapshot,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        SampleSection(title = stringResource(R.string.dev_lab_cards)) {
            DashboardLabWidthSample.entries.forEach { sample ->
                LabeledSample(
                    title = "${stringResource(sample.titleRes)} · ${sample.contentWidth.value.toInt()} dp",
                    caption = stringResource(sample.captionRes),
                ) {
                    CardSample(id = id, dashboard = dashboard, sample = sample)
                }
            }
        }
        SampleSection(title = stringResource(R.string.dev_lab_list)) {
            LabeledSample(
                title = "${stringResource(R.string.dev_lab_width_regular)} · ${DashboardLabWidthSample.listContentWidth.value.toInt()} dp",
                caption = stringResource(R.string.dev_lab_list_caption),
            ) {
                ListSample(id = id, dashboard = dashboard)
            }
        }
    }
}

@Composable
private fun SampleSection(
    title: String,
    content: @Composable () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        content()
    }
}

@Composable
private fun LabeledSample(
    title: String,
    caption: String,
    content: @Composable () -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(title, style = MaterialTheme.typography.titleSmall)
        Text(
            caption,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Column(Modifier.horizontalScroll(rememberScrollState())) {
            content()
        }
    }
}

@Composable
private fun CardSample(
    id: String,
    dashboard: DashboardSnapshot,
    sample: DashboardLabWidthSample,
) {
    val shape = RoundedCornerShape(28.dp)
    Column(
        modifier = Modifier
            .width(sample.outerWidth)
            .height(DashboardLabWidthSample.outerHeight)
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceContainerLow, shape)
            .padding(DashboardLabWidthSample.cardPadding),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            stringResource(DashboardLabModules.titleRes(id)),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        LabModuleView(id = id, dashboard = dashboard, shape = Bento.solo)
    }
}

@Composable
private fun ListSample(id: String, dashboard: DashboardSnapshot) {
    val shape = RoundedCornerShape(28.dp)
    Column(
        modifier = Modifier
            .width(DashboardLabWidthSample.listContentWidth)
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceContainerLow, shape)
            .padding(DashboardLabWidthSample.cardPadding),
    ) {
        LabModuleView(id = id, dashboard = dashboard, shape = Bento.solo)
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun LabModuleView(
    id: String,
    dashboard: DashboardSnapshot,
    shape: Shape,
) {
    when (id) {
        DashboardLabModules.MONTH_TO_DATE -> DashboardHeroHeader(
            state = dashboardHeroState(
                dashboard = dashboard,
                filterNote = null,
                includesSubscriptions = false,
                canToggleScope = false,
                nowMillis = System.currentTimeMillis(),
            ),
            fullBleed = false,
        )
        DashboardModules.COMPOSITION -> CompositionBarsCard(
            rows = dashboard.compositionSlices,
            onOpenRow = {},
            onOpenAll = {},
        )
        DashboardModules.ANOMALY,
        DashboardModules.BALANCE,
        DashboardModules.QUOTA,
        -> DashboardAttentionSection(
            summary = AttentionSummary.from(dashboard, listOf(id)),
            onOpen = {},
        )
        // 即将扣款已下架：旧版式里存着也不再画。
        DashboardModules.UPCOMING -> Unit
        DashboardModules.SERVICES -> PinnedServicesModuleView(
            items = dashboard.pinnedServices,
            onOpen = {},
            shape = shape,
        )
        DashboardModules.SUBSCRIPTIONS -> SubscriptionsModuleCard(
            module = dashboard.subscriptions,
            onOpen = {},
            shape = shape,
        )
        DashboardModules.HEATMAP -> HeatmapModuleView(
            months = dashboard.heatmap,
            onOpen = {},
            shape = shape,
        )
        DashboardModules.CATEGORIES -> CategoriesModuleView(
            slices = dashboard.categories,
            onOpen = {},
            shape = shape,
        )
        DashboardModules.SUPERLATIVES -> SuperlativesModuleView(
            items = dashboard.superlatives,
            onOpen = {},
            shape = shape,
        )
        DashboardModules.BUDGET -> dashboard.budget?.let { BudgetModuleView(it, shape = shape) }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DeveloperDashboardLabSamplesPreview() {
    TollCatTheme {
        DeveloperDashboardLabSamples(
            id = DashboardModules.COMPOSITION,
            dashboard = DashboardLabFixtures.contents,
            modifier = Modifier.padding(16.dp),
        )
    }
}
