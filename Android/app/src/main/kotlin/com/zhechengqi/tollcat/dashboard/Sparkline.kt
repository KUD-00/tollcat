package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.invisibleToUser
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme

/** 和 iOS `MeterSpacing.sparkline` 同一身量：特别关心行里只表示方向。 */
object SparklineDefaults {
    val width = 64.dp
    val height = 22.dp
}

/**
 * 迷你走势：一条线、一个末点，没有坐标轴。少于两个点不画。
 */
@Composable
fun Sparkline(
    values: List<Float>,
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.primary,
) {
    if (values.size < 2) return
    val ceiling = maxOf(values.maxOrNull() ?: 0f, 0.01f) * 1.15f
    Canvas(
        modifier
            .size(SparklineDefaults.width, SparklineDefaults.height)
            .semantics { invisibleToUser() },
    ) {
        val last = values.lastIndex
        val path = Path()
        values.forEachIndexed { index, value ->
            val x = size.width * index / last.toFloat()
            val y = size.height * (1f - (value / ceiling).coerceIn(0f, 1f))
            if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        drawPath(
            path = path,
            color = color,
            style = Stroke(
                width = 1.5.dp.toPx(),
                cap = StrokeCap.Round,
                join = StrokeJoin.Round,
            ),
        )
        val lastY = size.height * (1f - (values.last() / ceiling).coerceIn(0f, 1f))
        drawCircle(
            color = color,
            radius = 2.dp.toPx(),
            center = Offset(size.width, lastY),
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SparklinePreview() {
    TollCatTheme {
        Sparkline(values = listOf(6f, 8f, 7f, 9f, 10f, 11f))
    }
}
