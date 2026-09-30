package com.zhechengqi.tollcat.share

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.DashboardHeroHeader
import com.zhechengqi.tollcat.dashboard.DashboardModuleStack
import com.zhechengqi.tollcat.dashboard.DashboardModules
import com.zhechengqi.tollcat.dashboard.DashboardPreviewData
import com.zhechengqi.tollcat.dashboard.dashboardHeroState
import com.zhechengqi.tollcat.ui.LocalStaticRender
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.cat.CatMood
import com.zhechengqi.tollcat.ui.cat.CatView

/** 卡宽和 iOS 分享卡一样：432 按 2.5 倍渲成 1080 像素宽。 */
val ShareCardWidth = 432.dp

/** 9:16 的下限（432 × 16 / 9）。内容再多就往下长，不封顶——封顶等于把二维码切掉一半。 */
private val ShareCardMinHeight = 768.dp

private val CardGutter = 12.dp

/**
 * 分享图：**照着这个人自己的仪表盘出**，和 iOS `ShareCardView` 同一套骨架——
 * 品牌行、仪表顶上那块总数卡、内容纸上那一摞模块（同一批、同一个顺序、同一批组件）、
 * 落款和二维码。不另攒一套精简版：编辑面里开了什么，图上就有什么。
 *
 * 由 [ShareCardRenderer] 在浅色主题、`LocalStaticRender` 下渲成一帧位图。
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ShareCard(
    dashboard: DashboardSnapshot,
    order: List<String>,
    nowMillis: Long,
) {
    Column(
        modifier = Modifier
            .width(ShareCardWidth)
            .heightIn(min = ShareCardMinHeight)
            .background(MaterialTheme.colorScheme.surface)
            .padding(vertical = MeterSpacing.lg),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
            modifier = Modifier.padding(horizontal = MeterSpacing.xl),
        ) {
            CatView(mood = CatMood.Normal, size = MeterSpacing.xl, isAnimated = false)
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
        DashboardHeroHeader(
            state = dashboardHeroState(
                dashboard = dashboard,
                filterNote = dashboard.filterNote,
                includesSubscriptions = dashboard.subscriptionCaption != null,
                canToggleScope = false,
                nowMillis = nowMillis,
            ),
            fullBleed = false,
            modifier = Modifier.padding(horizontal = CardGutter),
        )
        // 仪表盘上不写「按日元显示」（货币是用户自己选的），图上要写：
        // 收到图的人不知道 ¥ 是人民币还是日元。
        dashboard.currencyNote?.let { note ->
            Text(
                text = note,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = MeterSpacing.xl),
            )
        }
        DashboardModuleStack(
            dashboard = dashboard,
            order = order,
            onOpenComposition = {},
            onOpenComparison = {},
            onOpenProvider = {},
            onOpenHeatmap = {},
            onOpenCategories = {},
            onOpenSubscriptions = {},
            itemModifier = Modifier.padding(horizontal = CardGutter),
        )
        Spacer(Modifier.height(MeterSpacing.xs))
        ShareCardFooter(modifier = Modifier.padding(horizontal = MeterSpacing.xl))
    }
}

@Composable
private fun ShareCardFooter(modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs)) {
            Text(
                text = stringResource(R.string.share_card_tagline),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Text(
                text = ShareCardHost,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        QrCode(modifier = Modifier.size(MeterSpacing.shareCardQR))
    }
}

/** 二维码写死指向官网，和 iOS `ShareCardBuilder.shareURL` 同一条红线：远程可改的地址等于让别人决定这张图把人送到哪。 */
private const val ShareCardHost = "tollcat.app"

@Composable
private fun QrCode(modifier: Modifier = Modifier) {
    val matrix = remember { QrMatrix.encode() }
    // 二维码固定黑白：扫码器认对比度，不认主题色。
    Canvas(modifier.background(Color.White)) {
        val cell = size.width / matrix.size
        for (y in 0 until matrix.size) {
            for (x in 0 until matrix.size) {
                if (matrix.dark(x, y)) {
                    drawRect(Color.Black, topLeft = Offset(x * cell, y * cell), size = Size(cell, cell))
                }
            }
        }
    }
}

@Preview(name = "Share card", widthDp = 432)
@Composable
private fun ShareCardPreview() {
    TollCatTheme {
        androidx.compose.runtime.CompositionLocalProvider(LocalStaticRender provides true) {
            ShareCard(
                dashboard = DashboardPreviewData.snapshot,
                order = DashboardModules.resolvedOrder(emptyList(), emptySet()),
                nowMillis = 1_786_881_600_000L,
            )
        }
    }
}
