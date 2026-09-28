package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.BudgetRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme

private val BarHeight = 20.dp
private val MarkerOverhang = 6.dp

/**
 * 预算线（替掉原来那两排格子——格子只说「满了」，看不出哪段是预算、哪段是超出）。
 *
 * - 没超：整条就是预算。实心段是已花，空着的是还剩，条尾就是预算那条线。
 * - 超了：整条是已花。预算那一段照常实心，过了预算线的部分换成红色斜纹，
 *   线的位置上立一根竖标，标上「预算 $X」；右下角写「超出 $Y」。
 */
@Composable
fun BudgetBar(budget: BudgetRow, modifier: Modifier = Modifier) {
    val over = budget.isOver
    val main = when {
        over -> MaterialTheme.colorScheme.primary
        budget.isClose -> MaterialTheme.colorScheme.tertiary
        else -> MaterialTheme.colorScheme.primary
    }
    val track = MaterialTheme.colorScheme.surfaceContainerHighest
    val danger = MaterialTheme.colorScheme.error
    val marker = MaterialTheme.colorScheme.onSurface
    // 超了：预算占整条（=已花）的 1/fraction；没超：已花占整条（=预算）的 fraction。
    val budgetShare = if (over) (1f / budget.fraction.coerceAtLeast(1f)) else 1f
    val spentShare = if (over) 1f else budget.fraction.coerceIn(0f, 1f)
    val markerLabel = stringResource(R.string.dashboard_budget_marker, budget.budgetText)
    val spentLabel = stringResource(R.string.dashboard_budget_spent, budget.spentText)
    val trailingLabel = if (over) {
        stringResource(R.string.dashboard_budget_over, budget.overText)
    } else {
        stringResource(R.string.dashboard_budget_remaining, budget.remainingText)
    }
    val labelStyle = MaterialTheme.typography.labelMedium
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { contentDescription = "$markerLabel，$spentLabel，$trailingLabel" },
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val width = maxWidth
            val markerX = width * budgetShare
            val labelWidth = with(density) { measurer.measure(markerLabel, labelStyle).size.width.toDp() }
            // 标签以竖标为右端对齐；贴到左边就不再往外推。
            val labelX = (markerX - labelWidth).coerceIn(0.dp, (width - labelWidth).coerceAtLeast(0.dp))
            Column {
                Box(Modifier.fillMaxWidth()) {
                    Text(
                        markerLabel,
                        style = labelStyle,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        modifier = Modifier.offset(x = labelX),
                    )
                }
                Spacer(Modifier.height(2.dp))
                Canvas(
                    Modifier
                        .fillMaxWidth()
                        .height(BarHeight + MarkerOverhang * 2),
                ) {
                    val top = MarkerOverhang.toPx()
                    val barH = BarHeight.toPx()
                    val radius = CornerRadius(barH / 2f)
                    val gap = 3.dp.toPx()
                    val budgetEnd = size.width * budgetShare
                    val bar = RoundRect(0f, top, size.width, top + barH, radius)
                    clipPath(Path().apply { addRoundRect(bar) }) {
                        if (over) {
                            drawRect(main, topLeft = Offset(0f, top), size = Size(budgetEnd - gap / 2f, barH))
                            drawOverage(budgetEnd + gap / 2f, top, size.width, barH, danger)
                        } else {
                            drawRect(track, topLeft = Offset(0f, top), size = Size(size.width, barH))
                            drawRect(main, topLeft = Offset(0f, top), size = Size(size.width * spentShare, barH))
                        }
                    }
                    // 预算那条线：超了立在分界处，没超就是条尾——都画出来，位置本身就是信息。
                    val x = if (over) budgetEnd else size.width - 1.dp.toPx()
                    drawLine(
                        color = marker,
                        start = Offset(x, 0f),
                        end = Offset(x, top * 2 + barH),
                        strokeWidth = 2.dp.toPx(),
                    )
                }
            }
        }
        Row(Modifier.fillMaxWidth()) {
            Text(spentLabel, style = labelStyle, color = MaterialTheme.colorScheme.onSurface, modifier = Modifier.weight(1f))
            Text(
                trailingLabel,
                style = labelStyle,
                fontWeight = if (over) FontWeight.Bold else FontWeight.Normal,
                color = if (over) danger else MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

private fun DrawScope.drawOverage(start: Float, top: Float, end: Float, height: Float, color: Color) {
    if (end <= start) return
    drawRect(color.copy(alpha = 0.28f), topLeft = Offset(start, top), size = Size(end - start, height))
    val step = 8.dp.toPx()
    var x = start - height
    while (x < end) {
        drawLine(
            color = color,
            start = Offset(maxOf(x, start), top + height - (maxOf(x, start) - x)),
            end = Offset(minOf(x + height, end), top + height - (minOf(x + height, end) - x)),
            strokeWidth = 3.dp.toPx(),
        )
        x += step
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun BudgetBarPreview() {
    TollCatTheme {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            BudgetBar(BudgetRow("$21.40", "$40.00", "$18.60", "$0.00", 0.535f, usedPercent = 54, isOver = false, isClose = false))
            BudgetBar(BudgetRow("$36.00", "$40.00", "$4.00", "$0.00", 0.9f, usedPercent = 90, isOver = false, isClose = true))
            BudgetBar(BudgetRow("$91.30", "$80.00", "$0.00", "$11.30", 1.14f, usedPercent = 114, isOver = true, isClose = true))
        }
    }
}
