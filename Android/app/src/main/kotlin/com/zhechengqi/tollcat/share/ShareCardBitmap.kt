package com.zhechengqi.tollcat.share

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.compose.ui.graphics.toArgb
import com.zhechengqi.tollcat.dashboard.CompositionTones
import com.zhechengqi.tollcat.tollCatBrandScheme
import com.zhechengqi.tollcat.ui.ContrastTier
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatStillRenderer
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * 把分享卡渲成 PNG 位图。配色锁成浅色——这张图会被转发到任何地方，
 * 跟着分享者的深色模式走会让收到的人看到一张黑卡。
 *
 * Preview 和生产走这一份：猫、构成条、右下角 QR。
 */
object ShareCardBitmap {
    const val WIDTH = 1080
    const val MIN_HEIGHT = 1920

    /**
     * 锁浅色，但**色值不自己发明**：从 App 的亮色品牌方案上取，
     * 和屏幕上那张构成条是同一组色。这里以前是第三套硬编码十六进制。
     */
    private val scheme = tollCatBrandScheme(dark = false, contrast = ContrastTier.Standard)

    private val page = scheme.surfaceContainerLow.toArgb()
    private val card = scheme.surface.toArgb()
    private val ink = scheme.onSurface.toArgb()
    private val secondary = scheme.onSurfaceVariant.toArgb()
    private val tertiary = scheme.outline.toArgb()
    private val brand = scheme.primary.toArgb()
    private val composition = IntArray(CompositionTones.namedLimit) { index ->
        CompositionTones.color(scheme, index).toArgb()
    }
    private val compositionOther = CompositionTones.color(scheme, 0, isOther = true).toArgb()

    fun render(content: ShareCardContent): Bitmap {
        val pad = 64f
        val inner = WIDTH - pad * 2
        val catSize = 100
        val qrSide = 180f
        val brandPaint = textPaint(ink, 42f, 600)
        val periodPaint = textPaint(ink, 64f, 700)
        val totalPaint = textPaint(ink, 96f, 700)
        val bodyPaint = textPaint(secondary, 28f, 400)
        val tertiaryPaint = textPaint(tertiary, 26f, 400)
        val notePaint = textPaint(brand, 26f, 500)
        val legendName = textPaint(ink, 28f, 500)
        val legendAmount = textPaint(secondary, 28f, 400)
        val taglinePaint = textPaint(ink, 28f, 500)
        val footPaint = textPaint(secondary, 24f, 400)

        val brandLayout = layout("TollCat", brandPaint, inner - catSize - 24f)
        val periodLayout = layout(content.periodTitle, periodPaint, inner)
        val totalLayout = layout(content.totalText, totalPaint, inner)
        val projectionLayout = content.projectionText?.let { layout(it, bodyPaint, inner) }
        val subscriptionLayout = content.subscriptionText?.let { layout(it, bodyPaint, inner) }
        val currencyLayout = content.currencyNote?.let { layout(it, tertiaryPaint, inner) }
        val filterLayout = content.filterNote?.let { layout(it, notePaint, inner) }
        val captionWidth = inner - qrSide - 24f
        val taglineLayout = layout(content.qrCaption, taglinePaint, captionWidth)
        val footLayout = layout(content.footnote, footPaint, captionWidth)

        val gap = 16f
        val block = 28f
        var cursor = pad
        cursor += max(catSize.toFloat(), brandLayout.height.toFloat()) + block
        cursor += periodLayout.height + 12f
        cursor += totalLayout.height
        if (projectionLayout != null) cursor += gap + projectionLayout.height
        if (subscriptionLayout != null) cursor += gap + subscriptionLayout.height
        if (currencyLayout != null) cursor += gap + currencyLayout.height
        if (filterLayout != null) cursor += gap + filterLayout.height

        val compositionTop = cursor + block
        val barH = 28f
        val legendRow = 44f
        val cardPad = 32f
        val compositionH = if (content.segments.isEmpty()) {
            0f
        } else {
            cardPad + barH + 24f + content.segments.size * legendRow + cardPad
        }
        if (compositionH > 0f) cursor = compositionTop + compositionH

        val footerH = max(qrSide, taglineLayout.height + 8f + footLayout.height.toFloat())
        cursor += 48f + footerH + pad
        val height = max(MIN_HEIGHT, cursor.roundToInt())

        val bitmap = Bitmap.createBitmap(WIDTH, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(page)

        var y = pad
        val cat = CatStillRenderer.bitmap(CatMood.Normal, catSize, dark = false)
        canvas.drawBitmap(cat, pad, y, null)
        if (!cat.isRecycled) cat.recycle()
        drawLayout(
            canvas,
            brandLayout,
            pad + catSize + 16f,
            y + (catSize - brandLayout.height) / 2f,
        )
        y += max(catSize.toFloat(), brandLayout.height.toFloat()) + block
        y = drawLayout(canvas, periodLayout, pad, y) + 12f
        y = drawLayout(canvas, totalLayout, pad, y)
        projectionLayout?.let { y = drawLayout(canvas, it, pad, y + gap) }
        subscriptionLayout?.let { y = drawLayout(canvas, it, pad, y + gap) }
        currencyLayout?.let { y = drawLayout(canvas, it, pad, y + gap) }
        filterLayout?.let { y = drawLayout(canvas, it, pad, y + gap) }

        if (content.segments.isNotEmpty()) {
            y += block
            val cardRect = RectF(pad, y, WIDTH - pad, y + compositionH)
            val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = card }
            canvas.drawRoundRect(cardRect, 36f, 36f, cardPaint)
            val barTop = y + cardPad
            drawBar(canvas, content.segments, pad + cardPad, barTop, inner - cardPad * 2, barH)
            var legendY = barTop + barH + 24f
            content.segments.forEachIndexed { index, segment ->
                val swatch = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = segmentColor(index, segment.isOther)
                }
                val cy = legendY + legendRow / 2f
                canvas.drawCircle(pad + cardPad + 10f, cy, 10f, swatch)
                val nameW = inner - cardPad * 2 - 160f
                val name = layout(segment.name, legendName, nameW)
                drawLayout(canvas, name, pad + cardPad + 32f, legendY + (legendRow - name.height) / 2f)
                if (segment.amountText.isNotBlank()) {
                    val amount = layout(segment.amountText, legendAmount, 140f)
                    drawLayout(
                        canvas,
                        amount,
                        WIDTH - pad - cardPad - amount.width,
                        legendY + (legendRow - amount.height) / 2f,
                    )
                }
                legendY += legendRow
            }
            y += compositionH
        }

        val footerY = max(y + 48f, height - pad - footerH)
        drawLayout(canvas, taglineLayout, pad, footerY)
        drawLayout(canvas, footLayout, pad, footerY + taglineLayout.height + 8f)
        drawQr(canvas, content.qrPayload, WIDTH - pad - qrSide, footerY, qrSide)
        return bitmap
    }

    private fun drawQr(canvas: Canvas, payload: String, left: Float, top: Float, side: Float) {
        val matrix = QrMatrix.encode(payload)
        val n = matrix.size
        val module = (side / n).toInt().coerceAtLeast(1)
        val drawn = module * n
        val bg = Paint().apply {
            color = Color.WHITE
            isAntiAlias = false
        }
        val fg = Paint().apply {
            color = Color.BLACK
            isAntiAlias = false
        }
        canvas.drawRect(left, top, left + drawn, top + drawn, bg)
        for (y in 0 until n) {
            for (x in 0 until n) {
                if (!matrix.dark(x, y)) continue
                val l = left + x * module
                val t = top + y * module
                canvas.drawRect(l, t, l + module, t + module, fg)
            }
        }
    }

    private fun drawBar(
        canvas: Canvas,
        segments: List<ShareCardContent.Segment>,
        x: Float,
        y: Float,
        width: Float,
        height: Float,
    ) {
        val gap = if (segments.size > 1) 6f else 0f
        val total = segments.sumOf { it.fraction.coerceAtLeast(0.01f).toDouble() }.toFloat()
        val available = width - gap * (segments.size - 1)
        var cx = x
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        segments.forEachIndexed { index, segment ->
            val w = available * (segment.fraction.coerceAtLeast(0.01f) / total)
            paint.color = segmentColor(index, segment.isOther)
            canvas.drawRoundRect(RectF(cx, y, cx + w, y + height), height / 2f, height / 2f, paint)
            cx += w + gap
        }
    }

    private fun segmentColor(index: Int, isOther: Boolean): Int {
        if (isOther) return compositionOther
        return composition[index.mod(composition.size)]
    }

    private fun textPaint(color: Int, size: Float, weight: Int): TextPaint {
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        paint.color = color
        paint.textSize = size
        paint.typeface = if (Build.VERSION.SDK_INT >= 28) {
            Typeface.create(Typeface.SANS_SERIF, weight, false)
        } else {
            Typeface.create(Typeface.SANS_SERIF, if (weight >= 600) Typeface.BOLD else Typeface.NORMAL)
        }
        paint.isSubpixelText = true
        return paint
    }

    private fun layout(text: String, paint: TextPaint, width: Float): StaticLayout {
        return StaticLayout.Builder
            .obtain(text, 0, text.length, paint, width.roundToInt().coerceAtLeast(1))
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setIncludePad(false)
            .build()
    }

    private fun drawLayout(canvas: Canvas, layout: StaticLayout, x: Float, y: Float): Float {
        canvas.save()
        canvas.translate(x, y)
        layout.draw(canvas)
        canvas.restore()
        return y + layout.height
    }
}
