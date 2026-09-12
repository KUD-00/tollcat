package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.TrendRow

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun TrendTileView(
    points: List<TrendRow>,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (points.size < 2) return
    val spoken = stringResource(R.string.module_trend)
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    // 数据到位时柱子从底部弹起，从旧月到本月依次起跳。
    val entrance = remember { Animatable(0f) }
    LaunchedEffect(points) {
        entrance.snapTo(0f)
        entrance.animateTo(1f, spatial)
    }
    val active = MaterialTheme.colorScheme.onTertiaryContainer
    val rest = active.copy(alpha = 0.30f)
    Surface(
        color = MaterialTheme.colorScheme.tertiaryContainer,
        contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = spoken },
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.module_trend),
                style = MaterialTheme.typography.labelLarge,
            )
            Canvas(
                Modifier
                    .fillMaxWidth()
                    .height(96.dp),
            ) {
                val count = points.size
                val gap = 6.dp.toPx()
                val slot = (size.width - gap * (count - 1)) / count
                // 柱宽封顶：月份少的时候柱子居槽而立，不摊成满宽的色板。
                val barWidth = minOf(slot, 40.dp.toPx())
                val radius = minOf(barWidth / 2f, 12.dp.toPx()).let { CornerRadius(it, it) }
                val last = points.lastIndex
                points.forEachIndexed { index, point ->
                    val delay = if (count > 1) index / (count * 2.4f) else 0f
                    val local = ((entrance.value - delay) / (1f - delay)).coerceIn(0f, 1f)
                    val fraction = point.fraction.coerceIn(0.04f, 1f)
                    val barHeight = fraction * size.height * local
                    if (barHeight <= 0f) return@forEachIndexed
                    drawRoundRect(
                        color = if (index == last) active else rest,
                        topLeft = Offset(
                            index * (slot + gap) + (slot - barWidth) / 2f,
                            size.height - barHeight,
                        ),
                        size = Size(barWidth, barHeight),
                        cornerRadius = radius,
                    )
                }
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                points.firstOrNull()?.let {
                    Text(it.month, style = MaterialTheme.typography.labelSmall)
                }
                points.lastOrNull()?.let {
                    Text(it.month, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TrendTileViewPreview() {
    TollCatTheme {
        TrendTileView(points = DashboardPreviewData.snapshot.trend)
    }
}
