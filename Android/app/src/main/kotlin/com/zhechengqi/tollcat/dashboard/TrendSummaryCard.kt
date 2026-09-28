@file:OptIn(ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.TrendRow

/**
 * 近几个月：左边标题 + 本月的数，右边一排柱，本月那根用 primary、其余压成中性色。
 * 单月不成趋势（一根柱会铺满整块），少于两个月整张不画。点进去是较上月同期的详情。
 */
@Composable
fun TrendSummaryCard(
    points: List<TrendRow>,
    modifier: Modifier = Modifier,
    onOpen: (() -> Unit)? = null,
) {
    if (points.size < 2) return
    val latest = points.last()
    val title = stringResource(R.string.module_trend)
    val progress = compositionEntrance(points)
    val active = MaterialTheme.colorScheme.primary
    val rest = MaterialTheme.colorScheme.outlineVariant
    val spoken = "$title。" + points.joinToString("，") { "${it.month} ${it.amount}" }
    Surface(
        onClick = onOpen ?: {},
        enabled = onOpen != null,
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = RoundedCornerShape(28.dp),
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = spoken },
    ) {
        Row(
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    title,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    latest.amount,
                    style = MaterialTheme.typography.headlineSmall.copy(fontFeatureSettings = "tnum"),
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                )
                Text(
                    latest.month,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Canvas(
                Modifier
                    .weight(1f)
                    .height(72.dp),
            ) {
                val count = points.size
                val gap = 6.dp.toPx()
                val slot = (size.width - gap * (count - 1)) / count
                // 柱宽封顶：月份少的时候柱子居槽而立，不摊成满宽的色板。
                val barWidth = minOf(slot, 32.dp.toPx())
                val radius = CornerRadius(minOf(barWidth / 2f, 8.dp.toPx()))
                points.forEachIndexed { index, point ->
                    val barHeight = point.fraction.coerceIn(0.06f, 1f) * size.height * progress
                    if (barHeight <= 0f) return@forEachIndexed
                    drawRoundRect(
                        color = if (index == count - 1) active else rest,
                        topLeft = Offset(index * (slot + gap) + (slot - barWidth) / 2f, size.height - barHeight),
                        size = Size(barWidth, barHeight),
                        cornerRadius = radius,
                    )
                }
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TrendSummaryCardPreview() {
    TollCatTheme {
        TrendSummaryCard(points = DashboardPreviewData.snapshot.trend, modifier = Modifier.padding(12.dp), onOpen = {})
    }
}
