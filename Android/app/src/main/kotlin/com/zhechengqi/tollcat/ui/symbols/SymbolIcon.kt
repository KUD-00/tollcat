package com.zhechengqi.tollcat.ui.symbols

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import kotlin.math.roundToInt

/**
 * Material Symbols Rounded 可变字体图标，取代 legacy 的 material-icons-extended。
 *
 * - 选中态是 FILL 轴 0↔1 的插值动画（M3 applying-icons 的官方定式），不再切换两套矢量。
 * - 深色主题自动 GRAD -25：浅色图标压在深底上会视觉发胖，负 grade 抵消 visual bleed。
 * - RTL 下方向性图标按 [MaterialSymbol.autoMirror] 水平镜像。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SymbolIcon(
    symbol: MaterialSymbol,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
    filled: Boolean = false,
    tint: Color = LocalContentColor.current,
) {
    val fill by animateFloatAsState(
        targetValue = if (filled) 1f else 0f,
        animationSpec = MaterialTheme.motionScheme.fastEffectsSpec(),
        label = "symbol-fill",
    )
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val family = symbolFontFamily(fill = fill, grade = if (dark) -25 else 0)
    val density = LocalDensity.current
    val fontSize = with(density) { size.toSp() }
    val mirrored = symbol.autoMirror && LocalLayoutDirection.current == LayoutDirection.Rtl
    val semantics = if (contentDescription != null) {
        Modifier.semantics {
            this.contentDescription = contentDescription
            role = Role.Image
        }
    } else {
        Modifier
    }
    val text = symbol.codepoint.toString()
    val textMeasurer = rememberTextMeasurer()
    // 导航栏选中指示按 24dp 盒子对中。Text 排版用 em/基线，Material Symbols 的墨水往往不在正中。
    val layout = remember(text, family, fontSize, density, textMeasurer) {
        textMeasurer.measure(
            text = text,
            style = TextStyle(
                fontFamily = family,
                fontSize = fontSize,
                platformStyle = PlatformTextStyle(includeFontPadding = false),
            ),
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Visible,
        )
    }
    val ink = remember(layout) {
        val outline = layout.getPathForRange(0, text.length).getBounds()
        if (outline.width > 0f && outline.height > 0f) {
            outline
        } else {
            Rect(0f, 0f, layout.size.width.toFloat(), layout.size.height.toFloat())
        }
    }
    Canvas(
        modifier = modifier
            .size(size)
            .then(semantics)
            .graphicsLayer { if (mirrored) scaleX = -1f },
    ) {
        drawText(
            textLayoutResult = layout,
            color = tint,
            topLeft = Offset(
                (this.size.width - ink.width) / 2f - ink.left,
                (this.size.height - ink.height) / 2f - ink.top,
            ),
        )
    }
}

/**
 * FILL 量化到 1/12 步进：每个变体实例对应一个 typeface，量化让动画期间
 * 复用缓存而不是逐帧建字体。opsz 固定 24（图标标准尺寸），wght 400。
 */
@Composable
private fun symbolFontFamily(fill: Float, grade: Int): FontFamily {
    val step = (fill.coerceIn(0f, 1f) * 12).roundToInt()
    return SymbolFontCache.family(step, grade)
}

private object SymbolFontCache {
    private val cache = HashMap<Int, FontFamily>()

    fun family(fillStep: Int, grade: Int): FontFamily {
        val key = fillStep * 1000 + grade
        return synchronized(cache) {
            cache.getOrPut(key) {
                FontFamily(
                    Font(
                        R.font.material_symbols_rounded,
                        variationSettings = FontVariation.Settings(
                            FontVariation.Setting("FILL", fillStep / 12f),
                            FontVariation.grade(grade),
                            FontVariation.Setting("opsz", 24f),
                            FontVariation.weight(400),
                        ),
                    ),
                )
            }
        }
    }
}
