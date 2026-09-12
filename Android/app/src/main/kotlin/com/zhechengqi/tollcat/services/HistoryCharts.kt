package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Density
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs

/**
 * 详情页历史图，规格对齐 iOS `DailySpendChart` / `BalanceLineChart`：
 * 整美元 Y 轴刻度、缺失不补零、推断段虚线、按住看某天的钱。
 * 7 / 30 天是看得见的宽度，多出来的桶横滑；12 个月整段铺进窗口。
 */

/** 轴刻度/气泡金额都走共享层的 formatUsd 写成显示货币——这里不再有 "$" 字面量。 */
private fun axisLabel(mark: Double): String = MoneyDisplay.formatUsd(trimmedDecimal(mark))

private fun detailLabel(amount: Double): String = MoneyDisplay.formatUsd(trimmedDecimal(amount))

private fun trimmedDecimal(value: Double): String =
    java.math.BigDecimal(value).toPlainString()

private val gutterStart = 40.dp
private val gutterBottom = 18.dp

fun HistoryRange.visibleSlotCount(): Int? = when (this) {
    HistoryRange.Days7 -> 7
    HistoryRange.Days30 -> 30
    HistoryRange.Months12 -> null
}

/** 图内几何：把 bucket 映射到像素。 */
private class ChartGeometry(
    val plot: Rect,
    private val slots: List<Long>,
) {
    private val slotWidth = if (slots.isEmpty()) 0f else plot.width / slots.size

    fun centerX(bucket: Long): Float {
        val index = slots.indexOf(bucket).coerceAtLeast(0)
        return plot.left + slotWidth * (index + 0.5f)
    }

    fun barWidth(maxDp: Float): Float = minOf(slotWidth * 0.62f, maxDp)

    fun y(amount: Double, top: Double): Float =
        plot.bottom - (amount / top).toFloat() * plot.height
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun SpendBarChart(
    content: HistoryChartState.Spend,
    modifier: Modifier = Modifier,
    visibleSlotCount: Int? = null,
) {
    val slots = content.buckets
    val marks = content.axisMarks
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    val entrance = remember(content) { Animatable(0f) }
    LaunchedEffect(content) { entrance.animateTo(1f, spatial) }
    var selected by remember(content) { mutableStateOf<ChartPoint?>(null) }

    val bar = MaterialTheme.colorScheme.primary
    val grid = MaterialTheme.colorScheme.outlineVariant
    val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
    val bubbleBg = MaterialTheme.colorScheme.inverseSurface
    val bubbleFg = MaterialTheme.colorScheme.inverseOnSurface
    val axisBg = MaterialTheme.colorScheme.surfaceContainer
    val labelStyle = MaterialTheme.typography.labelSmall
    val measurer = rememberTextMeasurer()

    ScrollableChart(
        slots = slots,
        visibleSlotCount = visibleSlotCount,
        marks = marks,
        monthly = content.monthly,
        grid = grid,
        labelColor = labelColor,
        axisBg = axisBg,
        labelStyle = labelStyle,
        measurer = measurer,
        modifier = modifier,
        onInspect = { geometry, x -> selected = nearest(content.points, geometry, x) },
        onInspectEnd = { selected = null },
    ) { geometry ->
        val top = marks.lastOrNull() ?: return@ScrollableChart
        val radius = CornerRadius(4.dp.toPx(), 4.dp.toPx())
        val width = geometry.barWidth(22.dp.toPx())
        content.points.forEach { point ->
            val x = geometry.centerX(point.bucketMillis)
            val fullHeight = geometry.plot.bottom - geometry.y(point.amount, top)
            val grown = fullHeight * entrance.value.coerceIn(0f, 1f)
            drawRoundRect(
                color = if (selected == null || selected == point) bar else bar.copy(alpha = 0.45f),
                topLeft = Offset(x - width / 2f, geometry.plot.bottom - grown),
                size = Size(width, grown),
                cornerRadius = radius,
            )
        }
        selected?.let { drawInspection(it, geometry, top, content.monthly, grid, bubbleBg, bubbleFg, labelStyle, measurer) }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun BalanceLineChart(
    content: HistoryChartState.Balance,
    modifier: Modifier = Modifier,
    visibleSlotCount: Int? = null,
) {
    val slots = content.buckets
    val marks = content.axisMarks
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    val entrance = remember(content) { Animatable(0f) }
    LaunchedEffect(content) { entrance.animateTo(1f, spatial) }
    var selected by remember(content) { mutableStateOf<ChartPoint?>(null) }

    val line = MaterialTheme.colorScheme.primary
    val grid = MaterialTheme.colorScheme.outlineVariant
    val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
    val bubbleBg = MaterialTheme.colorScheme.inverseSurface
    val bubbleFg = MaterialTheme.colorScheme.inverseOnSurface
    val axisBg = MaterialTheme.colorScheme.surfaceContainer
    val labelStyle = MaterialTheme.typography.labelSmall
    val measurer = rememberTextMeasurer()

    ScrollableChart(
        slots = slots,
        visibleSlotCount = visibleSlotCount,
        marks = marks,
        monthly = content.monthly,
        grid = grid,
        labelColor = labelColor,
        axisBg = axisBg,
        labelStyle = labelStyle,
        measurer = measurer,
        modifier = modifier,
        onInspect = { geometry, x -> selected = nearest(content.points, geometry, x) },
        onInspectEnd = { selected = null },
    ) { geometry ->
        val top = marks.lastOrNull() ?: return@ScrollableChart
        val dash = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx()))
        val strokeWidth = 2.dp.toPx()
        clipRect(right = geometry.plot.left + geometry.plot.width * entrance.value.coerceIn(0f, 1f)) {
            if (content.points.size >= 2) {
                content.points.zipWithNext { a, b ->
                    drawLine(
                        color = line,
                        start = Offset(geometry.centerX(a.bucketMillis), geometry.y(a.amount, top)),
                        end = Offset(geometry.centerX(b.bucketMillis), geometry.y(b.amount, top)),
                        strokeWidth = strokeWidth,
                        pathEffect = if (a.bucketMillis in content.inferredStarts) dash else null,
                    )
                }
            }
            content.points.forEach { point ->
                drawCircle(
                    color = line,
                    radius = if (selected == point) 5.5.dp.toPx() else 3.5.dp.toPx(),
                    center = Offset(geometry.centerX(point.bucketMillis), geometry.y(point.amount, top)),
                )
            }
        }
        selected?.let { drawInspection(it, geometry, top, content.monthly, grid, bubbleBg, bubbleFg, labelStyle, measurer) }
    }
}

@Composable
private fun ScrollableChart(
    slots: List<Long>,
    visibleSlotCount: Int?,
    marks: List<Double>,
    monthly: Boolean,
    grid: Color,
    labelColor: Color,
    axisBg: Color,
    labelStyle: TextStyle,
    measurer: TextMeasurer,
    modifier: Modifier,
    onInspect: (ChartGeometry, Float) -> Unit,
    onInspectEnd: () -> Unit,
    plot: DrawScope.(ChartGeometry) -> Unit,
) {
    val scroll = rememberScrollState()
    var pinned by remember(slots, visibleSlotCount) { mutableStateOf(false) }
    LaunchedEffect(scroll.maxValue) {
        if (!pinned && scroll.maxValue > 0) {
            scroll.scrollTo(scroll.maxValue)
            pinned = true
        }
    }
    BoxWithConstraints(modifier.fillMaxWidth().height(MeterSpacing.chartPlot)) {
        val viewport = maxWidth - gutterStart
        val visible = (visibleSlotCount ?: slots.size.coerceAtLeast(1)).coerceAtLeast(1)
        val contentWidth = if (slots.isEmpty()) viewport else viewport * slots.size / visible
        val canScroll = contentWidth > viewport
        Box {
            Box(
                Modifier
                    .padding(start = gutterStart)
                    .horizontalScroll(scroll, enabled = canScroll),
            ) {
                Canvas(
                    Modifier
                        .width(contentWidth)
                        .height(MeterSpacing.chartPlot)
                        .pointerInput(slots) {
                            detectDragGesturesAfterLongPress(
                                onDragStart = { offset ->
                                    onInspect(geometry(size.width.toFloat(), size.height.toFloat(), slots), offset.x)
                                },
                                onDrag = { change, _ ->
                                    onInspect(
                                        geometry(size.width.toFloat(), size.height.toFloat(), slots),
                                        change.position.x,
                                    )
                                    change.consume()
                                },
                                onDragEnd = onInspectEnd,
                                onDragCancel = onInspectEnd,
                            )
                        },
                ) {
                    val geometry = geometry(size.width, size.height, slots)
                    drawGrid(geometry, marks, grid)
                    drawXLabels(
                        geometry,
                        slots,
                        monthly,
                        labelColor,
                        labelStyle,
                        measurer,
                        visible,
                    )
                    plot(geometry)
                }
            }
            Canvas(
                Modifier
                    .width(gutterStart)
                    .height(MeterSpacing.chartPlot),
            ) {
                drawRect(axisBg)
                val geometry = geometry(size.width, size.height, slots)
                drawYLabels(geometry, marks, labelColor, labelStyle, measurer)
            }
        }
    }
}

private fun Density.geometry(width: Float, height: Float, slots: List<Long>): ChartGeometry =
    ChartGeometry(
        plot = Rect(
            left = 0f,
            top = 6.dp.toPx(),
            right = width,
            bottom = height - gutterBottom.toPx(),
        ),
        slots = slots,
    )

private fun nearest(points: List<ChartPoint>, geometry: ChartGeometry, x: Float): ChartPoint? =
    points.minByOrNull { abs(geometry.centerX(it.bucketMillis) - x) }

private fun DrawScope.drawGrid(
    geometry: ChartGeometry,
    marks: List<Double>,
    grid: Color,
) {
    val top = marks.lastOrNull() ?: return
    marks.forEach { mark ->
        val y = geometry.y(mark, top)
        drawLine(
            color = grid,
            start = Offset(geometry.plot.left, y),
            end = Offset(geometry.plot.right, y),
            strokeWidth = 1.dp.toPx(),
        )
    }
}

private fun DrawScope.drawYLabels(
    geometry: ChartGeometry,
    marks: List<Double>,
    labelColor: Color,
    labelStyle: TextStyle,
    measurer: TextMeasurer,
) {
    val top = marks.lastOrNull() ?: return
    marks.forEach { mark ->
        val y = geometry.y(mark, top)
        val text = measurer.measure(axisLabel(mark), labelStyle)
        drawText(
            text,
            color = labelColor,
            topLeft = Offset(
                (size.width - text.size.width - 6.dp.toPx()).coerceAtLeast(0f),
                (y - text.size.height / 2f).coerceIn(0f, size.height - text.size.height),
            ),
        )
    }
}

private fun DrawScope.drawXLabels(
    geometry: ChartGeometry,
    slots: List<Long>,
    monthly: Boolean,
    labelColor: Color,
    labelStyle: TextStyle,
    measurer: TextMeasurer,
    visibleSlots: Int,
) {
    if (slots.isEmpty()) return
    val format = SimpleDateFormat(if (monthly) "MMM" else "M/d", Locale.getDefault())
    val labelCount = if (monthly) 6 else 4
    val window = visibleSlots.coerceAtLeast(1)
    val step = maxOf(1, (window - 1) / (labelCount - 1))
    (slots.indices step step).forEach { index ->
        val bucket = slots[index]
        val text = measurer.measure(format.format(Date(bucket)), labelStyle)
        val x = (geometry.centerX(bucket) - text.size.width / 2f)
            .coerceIn(geometry.plot.left, geometry.plot.right - text.size.width)
        drawText(text, color = labelColor, topLeft = Offset(x, geometry.plot.bottom + 4.dp.toPx()))
    }
}

/** 按住的读数：竖直参考线 + 「日期 · $金额」气泡。 */
private fun DrawScope.drawInspection(
    point: ChartPoint,
    geometry: ChartGeometry,
    top: Double,
    monthly: Boolean,
    rule: Color,
    bubbleBg: Color,
    bubbleFg: Color,
    labelStyle: TextStyle,
    measurer: TextMeasurer,
) {
    val x = geometry.centerX(point.bucketMillis)
    drawLine(
        color = rule,
        start = Offset(x, geometry.plot.top),
        end = Offset(x, geometry.plot.bottom),
        strokeWidth = 1.dp.toPx(),
    )
    val format = SimpleDateFormat(if (monthly) "MMM" else "M/d", Locale.getDefault())
    val label = "${format.format(Date(point.bucketMillis))} · ${detailLabel(point.amount)}"
    val text = measurer.measure(label, labelStyle)
    val padH = 8.dp.toPx()
    val padV = 4.dp.toPx()
    val bubbleWidth = text.size.width + padH * 2
    val left = (x - bubbleWidth / 2f).coerceIn(geometry.plot.left, geometry.plot.right - bubbleWidth)
    drawRoundRect(
        color = bubbleBg,
        topLeft = Offset(left, 0f),
        size = Size(bubbleWidth, text.size.height + padV * 2),
        cornerRadius = CornerRadius(8.dp.toPx(), 8.dp.toPx()),
    )
    drawText(text, color = bubbleFg, topLeft = Offset(left + padH, padV))
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SpendBarChartPreview() {
    val start = 1_725_000_000_000L
    val day = 86_400_000L
    val buckets = (0 until 30).map { start + it * day }
    TollCatTheme {
        SpendBarChart(
            content = HistoryChartState.Spend(
                points = buckets.filterIndexed { index, _ -> index % 2 == 0 }.mapIndexed { index, bucket ->
                    ChartPoint(bucket, 2.0 + index)
                },
                startMillis = start,
                endMillis = start + 29 * day,
                monthly = false,
                isIntervalSpend = false,
                buckets = buckets,
                axisMarks = listOf(0.0, 8.0, 16.0),
            ),
            visibleSlotCount = 7,
        )
    }
}
