package com.zhechengqi.tollcat.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint

/**
 * 小组件构成条：画的是仪表盘同一份图例段（共享层合并好的前几名 + 其他），
 * 和 iOS 小组件一样按账号切片。这里只画，不合并。
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
