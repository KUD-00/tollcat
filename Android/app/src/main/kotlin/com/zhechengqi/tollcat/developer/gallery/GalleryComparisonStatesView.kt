package com.zhechengqi.tollcat.developer.gallery

import android.content.res.Configuration
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.TrendRow
import com.zhechengqi.tollcat.dashboard.TrendSummaryCard
import com.zhechengqi.tollcat.developer.GalleryFixtures

/**
 * 较上月同期挪进了顶栏那颗小药丸（三种语气在「总数顶栏」里看）；
 * 这里看近几个月那张卡：六个月、两个月、只有一个月（不画）。
 */
@Composable
fun GalleryComparisonStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    GalleryScaffold(
        title = stringResource(R.string.module_comparison),
        onBack = onBack,
        modifier = modifier,
    ) {
        GalleryExhibit(title = "近几个月：六个月") {
            TrendSummaryCard(points = GalleryFixtures.trend, onOpen = {})
        }
        GalleryExhibit(title = "近几个月：只有两个月") {
            TrendSummaryCard(
                points = listOf(TrendRow("7月", "$15.00", 0.68f), TrendRow("8月", "$21.00", 1f)),
                onOpen = {},
            )
        }
        GalleryExhibit(title = "只有一个月：整张卡不出现（一根柱会铺满整块）") {
            TrendSummaryCard(points = listOf(TrendRow("8月", "$21.00", 1f)), onOpen = {})
            Text(
                "↑ 这里应该是空的",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun GalleryComparisonStatesViewPreview() {
    TollCatTheme {
        GalleryComparisonStatesView(onBack = {})
    }
}
