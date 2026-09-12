package com.zhechengqi.tollcat.services

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.ProviderColors

/**
 * 品牌色圆角方块 + 单色 glyph，和 iOS `MeterDesign.ProviderGlyph`、site 同一份
 * 数据（shared/providers.json）：Simple Icons path 填墨色。拿不到官方 path 的
 * key 回落到同尺寸 tile 里的首字母，不手绘仿制 logo。
 */
@Composable
fun ServiceGlyph(
    name: String,
    colorKey: String,
    modifier: Modifier = Modifier,
    size: Dp = 28.dp,
) {
    // 跟着当前 ColorScheme 走，App 内强制深浅时也对。
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    // 浅色品牌色够深，白 glyph 过 3:1；深色色板把品牌色提亮之后白色掉到
    // 2.1–2.6，改用近黑才能读。和 iOS `MeterColor.providerGlyphInk` 同一条规则。
    val ink = if (dark) Color(0xFF0E1116) else Color.White
    val glyph = ProviderGlyphArtwork.path(colorKey)
    val fillRatio = ProviderGlyphArtwork.fillRatio(colorKey)
    Surface(
        modifier = modifier.size(size),
        // 系统 App 图标约 22% 边长的圆角，和 iOS `MeterRadius.glyph`（6/28）对齐。
        shape = RoundedCornerShape(size * (6f / 28f)),
        color = ProviderColors.of(colorKey, dark),
    ) {
        if (glyph != null) {
            Canvas(Modifier.fillMaxSize()) {
                val side = this.size.minDimension
                val glyphSide = side * fillRatio
                val inset = (side - glyphSide) / 2f
                translate(inset, inset) {
                    scale(glyphSide / 24f, glyphSide / 24f, pivot = Offset.Zero) {
                        drawPath(glyph, ink)
                    }
                }
            }
        } else {
            // 首字母占比抄 iOS `ProviderGlyph`：I/J/T 中空太多，28pt 上默认 0.64 掉到 5% 墨以下。
            val letter = ProviderGlyphArtwork.monogramLetter(colorKey)
            val ratio = when (letter) {
                "I" -> 0.92f
                "J", "T" -> 0.76f
                else -> 0.64f
            }
            val monogramSize = with(LocalDensity.current) { (size * ratio).toSp() }
            Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                Text(
                    text = ProviderGlyphArtwork.monogramLetter(colorKey),
                    color = ink,
                    fontSize = monogramSize,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}
