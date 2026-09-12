package com.zhechengqi.tollcat.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.dashboard.CompositionTones

/**
 * 小组件构成：5pt 条按厂商卷，超过 [CompositionTones.namedLimit] 家合成「其他」。
 * 仪表构成按账号切片；这里不能跟那份一对一行。
 */
object WidgetComposition {
    data class Slice(
        val providerId: String,
        val displayName: String,
        val amount: String,
        val percent: Int,
        val fraction: Float,
        val isOther: Boolean = false,
    )

    fun vendorSlices(
        rows: List<CompositionRow>,
        otherLabel: String,
        namedLimit: Int = CompositionTones.namedLimit,
    ): List<Slice> {
        val rolled = rows
            .groupBy { it.providerId.ifBlank { it.displayName } }
            .map { (id, group) ->
                Slice(
                    providerId = id,
                    displayName = group.first().displayName,
                    amount = if (group.size == 1) group.first().amount else "",
                    percent = group.sumOf { it.percent }.coerceAtMost(100),
                    fraction = group.sumOf { it.fraction.toDouble() }.toFloat(),
                )
            }
            .sortedByDescending { it.fraction }
        if (rolled.size <= namedLimit) return rolled
        val named = rolled.take(namedLimit)
        val rest = rolled.drop(namedLimit)
        val other = Slice(
            providerId = "other",
            displayName = otherLabel,
            amount = "",
            percent = rest.sumOf { it.percent }.coerceAtMost(100),
            fraction = rest.sumOf { it.fraction.toDouble() }.toFloat(),
            isOther = true,
        )
        return named + other
    }

    fun barBitmap(
        slices: List<Slice>,
        colors: List<Int>,
        widthPx: Int,
        heightPx: Int,
        gapPx: Int,
    ): Bitmap {
        val width = widthPx.coerceAtLeast(1)
        val height = heightPx.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        if (slices.isEmpty() || colors.isEmpty()) return bitmap
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
        val total = slices.sumOf { it.fraction.coerceAtLeast(0.01f).toDouble() }.toFloat().coerceAtLeast(0.01f)
        val gap = if (slices.size > 1) gapPx.coerceAtLeast(0).toFloat() else 0f
        val available = (width - gap * (slices.size - 1)).coerceAtLeast(1f)
        var x = 0f
        slices.forEachIndexed { index, slice ->
            val w = available * (slice.fraction.coerceAtLeast(0.01f) / total)
            paint.color = colors.getOrElse(index) { colors.last() }
            canvas.drawRect(x, 0f, x + w, height.toFloat(), paint)
            x += w + gap
        }
        return bitmap
    }
}
