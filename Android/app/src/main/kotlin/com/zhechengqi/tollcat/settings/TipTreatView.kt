package com.zhechengqi.tollcat.settings

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.min

/**
 * 糖果 / 咖啡 / 披萨。路径与 iOS `TipTreatArtwork` 同一份，热区在外面的购买按钮上。
 */
@Composable
fun TipTreatView(
    kind: TipTreatKind,
    size: Dp,
    modifier: Modifier = Modifier,
) {
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val palette = if (dark) TipTreatPalette.Dark else TipTreatPalette.Light
    val aspect = VIEW_BOX_HEIGHT / VIEW_BOX_WIDTH
    Canvas(
        modifier = modifier.size(width = size, height = size * aspect),
    ) {
        val unit = min(this.size.width / VIEW_BOX_WIDTH, this.size.height / VIEW_BOX_HEIGHT)
        val dx = (this.size.width - VIEW_BOX_WIDTH * unit) / 2f
        val dy = (this.size.height - VIEW_BOX_HEIGHT * unit) / 2f
        translate(dx, dy) {
            scale(unit, pivot = Offset.Zero) {
                when (kind) {
                    TipTreatKind.Candy -> drawCandy(palette, dark)
                    TipTreatKind.Coffee -> drawCoffee(palette)
                    TipTreatKind.Pizza -> drawPizza(palette)
                }
            }
        }
    }
}

@Immutable
private data class TipTreatPalette(
    val candy: Color,
    val candyWrapper: Color,
    val cupPaper: Color,
    val cupSleeve: Color,
    val cupLid: Color,
    val cheese: Color,
    val crust: Color,
    val crustEdge: Color,
    val pepperoni: Color,
) {
    companion object {
        val Light = TipTreatPalette(
            candy = Color(0xFFE0526A),
            candyWrapper = Color(0xFFF2A0AE),
            cupPaper = Color(0xFFD9B48D),
            cupSleeve = Color(0xFF8B5E3C),
            cupLid = Color(0xFF4A3A30),
            cheese = Color(0xFFEFB63C),
            crust = Color(0xFFD79A5B),
            crustEdge = Color(0xFFB57C43),
            pepperoni = Color(0xFFC0392B),
        )
        val Dark = TipTreatPalette(
            candy = Color(0xFFEC7387),
            candyWrapper = Color(0xFFF5B5C0),
            cupPaper = Color(0xFFC79C74),
            cupSleeve = Color(0xFFA06F49),
            cupLid = Color(0xFF5E4A3D),
            cheese = Color(0xFFE7B34B),
            crust = Color(0xFFC98E52),
            crustEdge = Color(0xFFA8743F),
            pepperoni = Color(0xFFD2503F),
        )
    }
}

private const val VIEW_BOX_WIDTH = 160f
private const val VIEW_BOX_HEIGHT = 118f

private fun DrawScope.drawCandy(palette: TipTreatPalette, dark: Boolean) {
    val rect = Rect(24f, 33f, 24f + 112f, 33f + 52f)
    val radius = rect.height / 2f
    val center = rect.center
    val wrappers = Path()
    for (side in listOf(-1f, 1f)) {
        val tip = Offset(center.x + side * rect.width / 2f, center.y)
        wrappers.moveTo(center.x + side * radius * 0.86f, center.y)
        wrappers.lineTo(tip.x, tip.y - rect.height * 0.42f)
        wrappers.lineTo(tip.x, tip.y + rect.height * 0.42f)
        wrappers.close()
    }
    drawPath(wrappers, palette.candyWrapper)
    drawOval(
        color = palette.candy,
        topLeft = Offset(center.x - radius, center.y - radius),
        size = Size(radius * 2f, radius * 2f),
    )
    drawOval(
        color = Color.White.copy(alpha = if (dark) 0.28f else 0.42f),
        topLeft = Offset(center.x - radius * 0.62f, center.y - radius * 0.66f),
        size = Size(radius * 0.7f, radius * 0.46f),
    )
}

private fun DrawScope.drawCoffee(palette: TipTreatPalette) {
    val rect = Rect(46f, 22f, 46f + 68f, 22f + 74f)
    val lidTop = rect.top + rect.height * 0.08f
    val bodyTop = rect.top + rect.height * 0.24f
    val topHalf = rect.width * 0.44f
    val bottomHalf = rect.width * 0.34f
    fun halfWidth(y: Float): Float {
        val t = (y - bodyTop) / (rect.bottom - bodyTop)
        return topHalf + (bottomHalf - topHalf) * t
    }

    val cup = Path().apply {
        moveTo(rect.center.x - topHalf, bodyTop)
        lineTo(rect.center.x + topHalf, bodyTop)
        lineTo(rect.center.x + bottomHalf, rect.bottom)
        lineTo(rect.center.x - bottomHalf, rect.bottom)
        close()
    }
    drawPath(cup, palette.cupPaper)

    val sleeveTop = bodyTop + (rect.bottom - bodyTop) * 0.3f
    val sleeveBottom = bodyTop + (rect.bottom - bodyTop) * 0.62f
    val sleeve = Path().apply {
        moveTo(rect.center.x - halfWidth(sleeveTop), sleeveTop)
        lineTo(rect.center.x + halfWidth(sleeveTop), sleeveTop)
        lineTo(rect.center.x + halfWidth(sleeveBottom), sleeveBottom)
        lineTo(rect.center.x - halfWidth(sleeveBottom), sleeveBottom)
        close()
    }
    drawPath(sleeve, palette.cupSleeve)

    drawRoundRect(
        color = palette.cupLid,
        topLeft = Offset(rect.center.x - rect.width * 0.13f, rect.top),
        size = Size(rect.width * 0.26f, lidTop - rect.top + 2f),
        cornerRadius = CornerRadius(2.4f, 2.4f),
    )
    drawRoundRect(
        color = palette.cupLid,
        topLeft = Offset(rect.left, lidTop),
        size = Size(rect.width, bodyTop - lidTop),
        cornerRadius = CornerRadius(4.5f, 4.5f),
    )
    drawRoundRect(
        color = Color.White.copy(alpha = 0.22f),
        topLeft = Offset(rect.center.x - topHalf * 0.78f, bodyTop + rect.height * 0.1f),
        size = Size(rect.width * 0.08f, rect.height * 0.44f),
        cornerRadius = CornerRadius(3f, 3f),
    )
}

private fun DrawScope.drawPizza(palette: TipTreatPalette) {
    val rect = Rect(36f, 24f, 36f + 88f, 24f + 72f)
    val crustHeight = rect.height * 0.22f
    val cheeseTop = rect.top + crustHeight
    val slice = Path().apply {
        moveTo(rect.left + rect.width * 0.03f, cheeseTop)
        lineTo(rect.right - rect.width * 0.03f, cheeseTop)
        lineTo(rect.center.x, rect.bottom)
        close()
    }
    drawPath(slice, palette.cheese)
    drawRoundRect(
        color = palette.crust,
        topLeft = Offset(rect.left, rect.top),
        size = Size(rect.width, crustHeight),
        cornerRadius = CornerRadius(crustHeight / 2f, crustHeight / 2f),
    )
    drawRoundRect(
        color = palette.crustEdge,
        topLeft = Offset(rect.left, rect.top),
        size = Size(rect.width, crustHeight),
        cornerRadius = CornerRadius(crustHeight / 2f, crustHeight / 2f),
        style = Stroke(width = 1.2f),
    )
    val toppings = listOf(
        Offset(rect.center.x - rect.width * 0.18f, cheeseTop + rect.height * 0.24f) to rect.width * 0.082f,
        Offset(rect.center.x + rect.width * 0.19f, cheeseTop + rect.height * 0.19f) to rect.width * 0.07f,
        Offset(rect.center.x, cheeseTop + rect.height * 0.5f) to rect.width * 0.062f,
    )
    for ((center, radius) in toppings) {
        drawOval(
            color = palette.pepperoni,
            topLeft = Offset(center.x - radius, center.y - radius),
            size = Size(radius * 2f, radius * 2f),
        )
    }
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun TipTreatViewPreview() {
    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        TipTreatKind.entries.forEach { kind ->
            TipTreatView(kind = kind, size = 76.dp)
        }
    }
}
