package com.zhechengqi.tollcat.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/** 目录的二十类（MeterCore `ProviderCategory` 的 rawValue）各一个 Material Symbol。 */
fun categorySymbol(category: String): MaterialSymbol = when (category) {
    "aiInference" -> MaterialSymbol.SmartToy
    "gpuCompute" -> MaterialSymbol.Memory
    "hosting" -> MaterialSymbol.Cloud
    "database" -> MaterialSymbol.Database
    "search" -> MaterialSymbol.Search
    "networkEdge" -> MaterialSymbol.Public
    "storage" -> MaterialSymbol.HardDrive
    "media" -> MaterialSymbol.Movie
    "devTools" -> MaterialSymbol.Code
    "ciCd" -> MaterialSymbol.Build
    "observability" -> MaterialSymbol.Monitoring
    "authSecurity" -> MaterialSymbol.Shield
    "payments" -> MaterialSymbol.Payments
    "messaging" -> MaterialSymbol.Chat
    "collaboration" -> MaterialSymbol.Groups
    "cms" -> MaterialSymbol.Article
    "analytics" -> MaterialSymbol.Insights
    "automation" -> MaterialSymbol.Bolt
    "dataPipeline" -> MaterialSymbol.AccountTree
    else -> MaterialSymbol.Category
}

/**
 * 类别小块：和厂商的品牌小块同一个位置、同一个尺寸，但颜色取自所在的色块（反色），
 * 类别没有品牌色可用。
 */
@Composable
fun CategoryGlyph(
    category: String,
    container: Color,
    content: Color,
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(size * (6f / 28f)))
            .background(container),
    ) {
        SymbolIcon(categorySymbol(category), contentDescription = null, size = size * 0.7f, tint = content, filled = true)
    }
}
