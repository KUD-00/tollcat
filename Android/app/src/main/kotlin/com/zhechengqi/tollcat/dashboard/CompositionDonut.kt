package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.TollCatTheme

/**
 * 构成圆环。中心留空，只服务图例对照；数字在旁边的行里，不挤进环心。
 * 入场时每一段在自己的槽位里顺时针长满，槽位不动，看着不转盘子。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CompositionDonut(
    slices: List<CompositionRow>,
    modifier: Modifier = Modifier,
    diameter: Dp = 132.dp,
    strokeWidth: Dp = 16.dp,
) {
    if (slices.isEmpty()) return
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    val entrance = remember { Animatable(0f) }
    LaunchedEffect(slices) {
        entrance.snapTo(0f)
        entrance.animateTo(1f, spatial)
    }
    val colors = slices.mapIndexed { index, row ->
        CompositionTones.color(index, isOther = row.providerId == "other")
    }
    Canvas(modifier.size(diameter)) {
        val stroke = Stroke(width = strokeWidth.toPx())
        val inset = strokeWidth.toPx() / 2f
        val arcSize = Size(size.width - strokeWidth.toPx(), size.height - strokeWidth.toPx())
        val gapDegrees = if (slices.size > 1) 4f else 0f
        val sweepBudget = 360f - gapDegrees * slices.size
        val total = slices.sumOf { it.fraction.coerceAtLeast(0.005f).toDouble() }.toFloat()
        val grown = entrance.value.coerceIn(0f, 1f)
        var start = -90f
        slices.forEachIndexed { index, row ->
            val full = sweepBudget * (row.fraction.coerceAtLeast(0.005f) / total)
            val sweep = full * grown
            if (sweep > 0f) {
                drawArc(
                    color = colors[index],
                    startAngle = start,
                    sweepAngle = sweep,
                    useCenter = false,
                    topLeft = Offset(inset, inset),
                    size = arcSize,
                    style = stroke,
                )
            }
            start += full + gapDegrees
        }
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionDonutPreview() {
    TollCatTheme {
        CompositionDonut(slices = DashboardPreviewData.snapshot.composition)
    }
}
