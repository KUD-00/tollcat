package com.zhechengqi.tollcat

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.ui.MeterSpacing

/** 仪表侧的 28dp glyph。DESIGN-BAR：品牌色只活在这一块 tile 里。 */
@Composable
fun ProviderGlyph(name: String, modifier: Modifier = Modifier, colorKey: String? = null) {
    ServiceGlyph(
        name = name,
        colorKey = colorKey ?: name,
        modifier = modifier,
        size = MeterSpacing.providerGlyph,
    )
}
