package com.zhechengqi.tollcat.ui

import android.content.res.Configuration
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 空态插画：35 形状库里挑一个容器，图标坐在里面。
 * 每一种空态换形状，不换圆角矩形——辨识度来自形，不是来自换一套图标颜色。
 */
@Composable
fun EmptyStateGlyph(
    symbol: MaterialSymbol,
    shape: Shape,
    modifier: Modifier = Modifier,
    size: Dp = 96.dp,
    iconSize: Dp = 40.dp,
    containerColor: Color = MaterialTheme.colorScheme.secondaryContainer,
    contentColor: Color = MaterialTheme.colorScheme.onSecondaryContainer,
) {
    Surface(
        modifier = modifier.size(size),
        shape = shape,
        color = containerColor,
        contentColor = contentColor,
    ) {
        Box(contentAlignment = Alignment.Center) {
            SymbolIcon(symbol, contentDescription = null, size = iconSize)
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun EmptyStateGlyphPreview() {
    TollCatTheme {
        EmptyStateGlyph(
            symbol = MaterialSymbol.Search,
            shape = MaterialShapes.Cookie4Sided.toShape(),
        )
    }
}
