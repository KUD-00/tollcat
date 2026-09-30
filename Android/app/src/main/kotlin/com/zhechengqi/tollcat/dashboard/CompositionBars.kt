@file:OptIn(ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import androidx.compose.foundation.layout.heightIn
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.LocalStaticRender
import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.launch.LocalLaunchSwatches
import com.zhechengqi.tollcat.launch.launchSwatch
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.ui.LocalReduceMotion
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

private val BarHeight = 44.dp
private val BarShape = RoundedCornerShape(14.dp)
private val AmountSlot = 84.dp

/**
 * 构成：横向粗条（画布 H1）。条长 = 占最大那家的比例，长度可以直接比；
 * 名字塞得进条就写在条里，塞不进就跟在条后面。条的颜色取 scheme 色阶（[CompositionTones.fill]），
 * 品牌色只留在条头的 [ServiceGlyph] 小块里——DESIGN-BAR「品牌色只活在图标块里」。
 */
@Composable
fun CompositionBarsCard(
    rows: List<CompositionRow>,
    onOpenRow: ((String) -> Unit)?,
    onOpenAll: () -> Unit,
    modifier: Modifier = Modifier,
    title: String = stringResource(R.string.module_composition),
    /** 条头的小块。默认是厂商的品牌小块；按类别构成传类别图标。「其他」那一段不画。 */
    leading: @Composable (row: CompositionRow, tone: TonePair) -> Unit = { row, _ ->
        ServiceGlyph(name = row.displayName, colorKey = row.colorKey.ifBlank { row.providerId }, size = 24.dp)
    },
) {
    if (rows.isEmpty()) return
    // 传进来的已经是最终的段：构成传共享层合并好的 `compositionSlices`，按类别传全部类别。
    // 这里不再合并——合并要把金额加起来，而这一端手上只有写好的字。
    val slices = rows
    val maxFraction = slices.maxOf { it.fraction }.coerceAtLeast(0.0001f)
    val progress = compositionEntrance(slices)
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = RoundedCornerShape(28.dp),
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            CompositionCardHeader(onOpenAll = onOpenAll, title = title)
            slices.forEachIndexed { index, row ->
                CompositionBarRow(
                    row = row,
                    tone = CompositionTones.fill(index, isOther = row.providerId == "other"),
                    ratio = row.fraction / maxFraction,
                    progress = progress,
                    onOpen = onOpenRow?.let { dashboardOpenAction(row.accountId, row.providerId, it) },
                    leading = leading,
                )
            }
        }
    }
}

/** 构成类卡片的统一卡头：标题 + 进构成详情的箭头钮。 */
@Composable
internal fun CompositionCardHeader(
    onOpenAll: () -> Unit,
    title: String = stringResource(R.string.module_composition),
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .padding(start = 4.dp)
            .heightIn(min = MeterSpacing.minTap),
    ) {
        Text(
            title,
            style = MaterialTheme.typography.titleLargeEmphasized,
            modifier = Modifier.weight(1f),
        )
        // 渲成分享图时不画：图上点不了。
        if (!LocalStaticRender.current) IconButton(onClick = onOpenAll, shapes = IconButtonDefaults.shapes()) {
            SymbolIcon(
                MaterialSymbol.ArrowForward,
                contentDescription = stringResource(R.string.dashboard_composition_hint),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun CompositionBarRow(
    row: CompositionRow,
    tone: TonePair,
    ratio: Float,
    progress: Float,
    onOpen: (() -> Unit)?,
    leading: @Composable (row: CompositionRow, tone: TonePair) -> Unit,
) {
    val isOther = row.providerId == "other"
    val nameStyle = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold)
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val spoken = "${row.displayName}，${row.amount}，${row.percent}%"
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxWidth()
            .clip(BarShape)
            .then(if (onOpen != null) Modifier.clickable(onClick = onOpen) else Modifier)
            .semantics(mergeDescendants = true) { contentDescription = spoken },
    ) {
        val maxBar = maxWidth - AmountSlot - 8.dp
        val bar = (maxBar * ratio).coerceIn(BarHeight, maxBar)
        val nameWidth = with(density) { measurer.measure(row.displayName, nameStyle).size.width.toDp() }
        val glyphWidth = if (isOther) 0.dp else 24.dp + 8.dp
        val nameFits = 12.dp + glyphWidth + nameWidth + 12.dp <= bar
        Row(verticalAlignment = Alignment.CenterVertically) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier
                    .width(bar * progress)
                    .height(BarHeight)
                    .clip(BarShape)
                    .background(tone.container)
                    .padding(start = 10.dp),
            ) {
                if (!isOther) {
                    // 冷启动过渡里口袋的圆牌落在这块上。
                    Box(Modifier.launchSwatch(LocalLaunchSwatches.current, row.id)) {
                        leading(row, tone)
                    }
                }
                if (nameFits) {
                    Text(row.displayName, style = nameStyle, color = tone.content, maxLines = 1)
                }
            }
            // 名字跟在条后面时它自己吃掉剩余宽度；塞进条里时换一个空白撑开。两者只能有一个带 weight，
            // 否则两份 weight 平分剩余空间，金额就不再贴右。
            if (nameFits) {
                Spacer(Modifier.weight(1f))
            } else {
                Spacer(Modifier.width(10.dp))
                Text(
                    row.displayName,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
            }
            Text(
                row.amount,
                style = MaterialTheme.typography.titleMedium.copy(fontFeatureSettings = "tnum"),
                fontWeight = FontWeight.Bold,
                maxLines = 1,
            )
        }
    }
}

/** 构成图共用的入场：数据到位时从 0 长到 1；「移除动画」时直接到位。 */
@Composable
internal fun compositionEntrance(key: Any): Float {
    val reduceMotion = LocalReduceMotion.current
    val spatial = MaterialTheme.motionScheme.slowSpatialSpec<Float>()
    val progress = remember { Animatable(if (reduceMotion) 1f else 0f) }
    LaunchedEffect(key, reduceMotion) {
        if (reduceMotion) {
            progress.snapTo(1f)
        } else {
            progress.snapTo(0f)
            progress.animateTo(1f, spatial)
        }
    }
    return progress.value
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionBarsCardPreview() {
    TollCatTheme {
        CompositionBarsCard(
            rows = DashboardPreviewData.snapshot.composition,
            onOpenRow = {},
            onOpenAll = {},
            modifier = Modifier.padding(12.dp),
        )
    }
}
