@file:OptIn(ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.ServiceGlyph
import kotlin.math.sqrt

/*
 * 构成的另外三种画法（画布 P2-2 / P2-3 / P2-5）。仪表盘主页用横向粗条（CompositionBars），
 * 这三种进组件画廊当备选；分段条本身也被构成详情、按类别、服务花费拿去替掉了甜甜圈。
 * 颜色一律取 scheme 色阶，品牌色只在 ServiceGlyph 小块里。
 */

/** 分段条 + 前三名（画布 P2-2）。 */
@Composable
fun CompositionSegmentsCard(
    rows: List<CompositionRow>,
    onOpenRow: (String) -> Unit,
    onOpenAll: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (rows.isEmpty()) return
    val slices = rows
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = RoundedCornerShape(28.dp),
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            CompositionCardHeader(onOpenAll = onOpenAll)
            CompositionSegmentBar(slices = slices, height = 56.dp, showsGlyphs = true)
            Column(
                verticalArrangement = Arrangement.spacedBy(2.dp),
                modifier = Modifier.clip(RoundedCornerShape(20.dp)),
            ) {
                slices.take(3).forEachIndexed { index, row ->
                    val action = dashboardOpenAction(row.accountId, row.providerId, onOpenRow)
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.surfaceContainerHigh)
                            .then(if (action != null) Modifier.clickable(onClick = action) else Modifier)
                            .padding(horizontal = 16.dp)
                            .height(52.dp)
                            .semantics(mergeDescendants = true) {
                                contentDescription = "${row.displayName}，${row.amount}，${row.percent}%"
                            },
                    ) {
                        Box(
                            Modifier
                                .size(12.dp)
                                .clip(CircleShape)
                                .background(CompositionTones.color(index, isOther = row.providerId == "other")),
                        )
                        Text(row.displayName, style = MaterialTheme.typography.bodyLarge, maxLines = 1, modifier = Modifier.weight(1f))
                        Text(
                            "${row.percent}%",
                            style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Text(
                            row.amount,
                            style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
        }
    }
}

/**
 * 分段条：段宽 = 占比，段间 3dp 缝，外侧两端大圆角、内侧小圆角。
 * [showsGlyphs] 时段够宽就在段里放品牌小块（按厂商构成）；按类别构成不放。
 */
@Composable
fun CompositionSegmentBar(
    slices: List<CompositionRow>,
    modifier: Modifier = Modifier,
    height: Dp = 20.dp,
    showsGlyphs: Boolean = false,
) {
    if (slices.isEmpty()) return
    val progress = compositionEntrance(slices)
    val outer = height * 0.36f
    val inner = minOf(6.dp, outer)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .semantics(mergeDescendants = true) {
                contentDescription = slices.joinToString("，") { "${it.displayName} ${it.percent}%" }
            },
        horizontalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        slices.forEachIndexed { index, row ->
            val shape = RoundedCornerShape(
                topStart = if (index == 0) outer else inner,
                bottomStart = if (index == 0) outer else inner,
                topEnd = if (index == slices.lastIndex) outer else inner,
                bottomEnd = if (index == slices.lastIndex) outer else inner,
            )
            BoxWithConstraints(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .weight(row.fraction.coerceAtLeast(0.02f))
                    .fillMaxHeight()
                    .scale(scaleX = progress, scaleY = 1f)
                    .clip(shape)
                    .background(CompositionTones.color(index, isOther = row.providerId == "other")),
            ) {
                if (showsGlyphs && row.providerId != "other" && maxWidth >= 40.dp && height >= 32.dp) {
                    ServiceGlyph(name = row.displayName, colorKey = row.colorKey.ifBlank { row.providerId }, size = 28.dp)
                }
            }
        }
    }
}

/** 形状拼贴（画布 P2-3）：每家一个形状库里的形状，面积 ≈ 花费。 */
@Composable
fun CompositionShapeCluster(
    rows: List<CompositionRow>,
    onOpenRow: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (rows.isEmpty()) return
    // 只有五个落点：超过五家时前四家单独、其余合成「其他」，不能把「其他」挤掉。
    // 共享层给的是前 5 名 + 「其他」，最多 6 段，正好 6 个落点。
    val slices = rows.take(ClusterSlots.size)
    val shapes = listOf(
        MaterialShapes.Cookie9Sided,
        MaterialShapes.Sunny,
        MaterialShapes.Clover4Leaf,
        MaterialShapes.Puffy,
        MaterialShapes.Gem,
    ).map { it.toShape() }
    val progress = compositionEntrance(slices)
    val lead = slices.first().fraction.coerceAtLeast(0.0001f)
    BoxWithConstraints(modifier.fillMaxWidth().aspectRatio(ClusterWidth / ClusterHeight)) {
        val unit = maxWidth / ClusterWidth
        slices.forEachIndexed { index, row ->
            val slot = ClusterSlots[index]
            val diameter = (ClusterLead * sqrt(row.fraction / lead)).coerceIn(56f, slot.size)
            val centerX = slot.x + slot.size / 2f
            val centerY = slot.y + slot.size / 2f
            val tone = CompositionTones.fill(index, row.providerId == "other")
            val action = dashboardOpenAction(row.accountId, row.providerId, onOpenRow)
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .offset(x = unit * (centerX - diameter / 2f), y = unit * (centerY - diameter / 2f))
                    .size(unit * diameter)
                    .scale(0.4f + 0.6f * progress)
                    .clip(shapes[index])
                    .background(tone.container)
                    .then(if (action != null) Modifier.clickable(onClick = action) else Modifier)
                    .semantics(mergeDescendants = true) {
                        contentDescription = "${row.displayName}，${row.amount}，${row.percent}%"
                    },
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    if (row.providerId != "other") {
                        ServiceGlyph(
                            name = row.displayName,
                            colorKey = row.colorKey.ifBlank { row.providerId },
                            size = if (diameter >= 110f) 32.dp else 22.dp,
                        )
                    }
                    Text(
                        row.amount,
                        style = (if (diameter >= 110f) MaterialTheme.typography.titleMedium else MaterialTheme.typography.labelMedium)
                            .copy(fontFeatureSettings = "tnum"),
                        fontWeight = FontWeight.Bold,
                        color = tone.content,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

private const val ClusterWidth = 388f
private const val ClusterHeight = 300f
private const val ClusterLead = 190f

private data class ClusterSlot(val x: Float, val y: Float, val size: Float)

/**
 * 画布 H4 那张图里的落点（388×300 坐标），按花费从大到小依次坐进去，互不重叠。
 * 六个：前 5 名 + 「其他」（和共享层 `CompositionSliceBuilder.namedLimit` 对齐）。
 */
private val ClusterSlots = listOf(
    ClusterSlot(4f, 26f, 190f),
    ClusterSlot(208f, 0f, 136f),
    ClusterSlot(200f, 146f, 113f),
    ClusterSlot(120f, 214f, 84f),
    ClusterSlot(318f, 150f, 68f),
    ClusterSlot(322f, 228f, 60f),
)

/** 方块树图（画布 P2-5）：bento 本身就是图。最大的一家占左栏，其余在右边按比例切。 */
@Composable
fun CompositionTreemap(
    rows: List<CompositionRow>,
    onOpenRow: (String) -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 250.dp,
) {
    if (rows.isEmpty()) return
    val slices = rows
    val tiles = slices.mapIndexed { index, row ->
        TreemapTile(row, CompositionTones.fill(index, row.providerId == "other"), dashboardOpenAction(row.accountId, row.providerId, onOpenRow))
    }
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(RoundedCornerShape(28.dp)),
    ) {
        TreemapArea(tiles, horizontal = true)
    }
}

private data class TreemapTile(val row: CompositionRow, val tone: TonePair, val onOpen: (() -> Unit)?)

/** 头一块按占比吃掉一边（夹在 35%–62%，太窄太宽都读不出字），剩下的换方向递归切。 */
@Composable
private fun TreemapArea(tiles: List<TreemapTile>, horizontal: Boolean) {
    if (tiles.size == 1) {
        TreemapCell(tiles.first(), Modifier.fillMaxSize())
        return
    }
    val total = tiles.sumOf { it.row.fraction.toDouble() }.toFloat().coerceAtLeast(0.0001f)
    val lead = (tiles.first().row.fraction / total).coerceIn(0.35f, 0.62f)
    val rest = tiles.drop(1)
    if (horizontal) {
        Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            TreemapCell(tiles.first(), Modifier.weight(lead).fillMaxHeight())
            Box(Modifier.weight(1f - lead).fillMaxHeight()) { TreemapArea(rest, horizontal = false) }
        }
    } else {
        Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            TreemapCell(tiles.first(), Modifier.weight(lead).fillMaxWidth())
            Box(Modifier.weight(1f - lead).fillMaxWidth()) { TreemapArea(rest, horizontal = true) }
        }
    }
}

@Composable
private fun TreemapCell(tile: TreemapTile, modifier: Modifier) {
    val row = tile.row
    BoxWithConstraints(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(tile.tone.container)
            .then(if (tile.onOpen != null) Modifier.clickable(onClick = tile.onOpen) else Modifier)
            .semantics(mergeDescendants = true) {
                contentDescription = "${row.displayName}，${row.amount}，${row.percent}%"
            }
            .padding(12.dp),
    ) {
        val roomy = maxWidth >= 88.dp && maxHeight >= 72.dp
        val glyph = row.providerId != "other"
        if (roomy) {
            Column(Modifier.fillMaxSize()) {
                if (glyph) {
                    ServiceGlyph(name = row.displayName, colorKey = row.colorKey.ifBlank { row.providerId }, size = 28.dp)
                }
                Spacer(Modifier.weight(1f))
                Text(
                    row.displayName,
                    style = MaterialTheme.typography.labelMedium,
                    color = tile.tone.content,
                    maxLines = 1,
                )
                Text(
                    row.amount,
                    style = MaterialTheme.typography.titleLarge.copy(fontFeatureSettings = "tnum"),
                    fontWeight = FontWeight.Bold,
                    color = tile.tone.content,
                    maxLines = 1,
                )
            }
        } else if (glyph && maxWidth >= 28.dp && maxHeight >= 28.dp) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                ServiceGlyph(name = row.displayName, colorKey = row.colorKey.ifBlank { row.providerId }, size = 24.dp)
            }
        }
    }
}

@Preview(name = "Light", showBackground = true, heightDp = 1100)
@Preview(name = "Dark", showBackground = true, heightDp = 1100, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionVariantsPreview() {
    TollCatTheme {
        val rows = DashboardPreviewData.snapshot.composition
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CompositionSegmentsCard(rows = rows, onOpenRow = {}, onOpenAll = {})
            CompositionShapeCluster(rows = rows, onOpenRow = {})
            CompositionTreemap(rows = rows, onOpenRow = {})
        }
    }
}
