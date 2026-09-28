@file:OptIn(ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.ServiceGlyph
import com.zhechengqi.tollcat.ui.heroAmountTextStyle
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

private val Outer = 28.dp
private val Inner = 8.dp
private val SectionPadding = 12.dp

/**
 * 「需要注意」一节（画布 R2-1）：最急的一件是一条横幅，其余横滑的大数字小卡，
 * 两者接成一组 bento（横幅下沿、小卡上沿收小角）。一件都没有时整节不出现。
 */
@Composable
fun DashboardAttentionSection(
    summary: AttentionSummary,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (summary.isEmpty) return
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(3.dp)) {
        val urgent = summary.urgent
        if (urgent == null) {
            AttentionHeader(count = summary.count)
        } else {
            UrgentAttentionBanner(
                item = urgent,
                onOpen = onOpen,
                shape = if (summary.others.isEmpty()) {
                    RoundedCornerShape(Outer)
                } else {
                    RoundedCornerShape(Outer, Outer, Inner, Inner)
                },
                modifier = Modifier.padding(horizontal = SectionPadding),
            )
        }
        if (summary.others.isNotEmpty()) {
            AttentionCardRow(items = summary.others, onOpen = onOpen, joinedToBanner = urgent != null)
        }
    }
}

@Composable
private fun AttentionHeader(count: Int) {
    Row(
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(start = SectionPadding + 8.dp, end = SectionPadding, top = 12.dp, bottom = 6.dp),
    ) {
        Text(stringResource(R.string.dashboard_attention), style = MaterialTheme.typography.titleLargeEmphasized)
        Text(
            count.toString(),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/** 最急那一件：errorContainer 横幅，一句完整的话 + 右侧圆形箭头。整条可点。 */
@Composable
fun UrgentAttentionBanner(
    item: AttentionItem,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(Outer),
) {
    val sentence = attentionSentence(item)
    val target = item.target
    val container = MaterialTheme.colorScheme.errorContainer
    val content = MaterialTheme.colorScheme.onErrorContainer
    Surface(
        onClick = { target?.let(onOpen) },
        enabled = target != null,
        color = container,
        contentColor = content,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = sentence },
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.padding(start = 20.dp, end = 12.dp, top = 16.dp, bottom = 16.dp),
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    SymbolIcon(MaterialSymbol.Warning, contentDescription = null, size = 16.dp, filled = true)
                    Text(
                        stringResource(R.string.dashboard_attention),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                    )
                }
                Text(sentence, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            }
            if (target != null) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(content),
                ) {
                    SymbolIcon(MaterialSymbol.ArrowForward, contentDescription = null, tint = container)
                }
            }
        }
    }
}

/** 横滑的大数字小卡。[joinedToBanner] 时首张收左上角、和上面的横幅接成一组。 */
@Composable
fun AttentionCardRow(
    items: List<AttentionItem>,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
    joinedToBanner: Boolean = false,
) {
    LazyRow(
        modifier = modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = SectionPadding),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        itemsIndexed(items, key = { index, item -> "${item.accountId}-${item.providerId}-$index" }) { index, item ->
            val shape = if (joinedToBanner) {
                RoundedCornerShape(
                    topStart = Inner,
                    topEnd = Inner,
                    bottomEnd = if (index == items.lastIndex) Outer else Inner,
                    bottomStart = if (index == 0) Outer else Inner,
                )
            } else {
                RoundedCornerShape(Outer)
            }
            AttentionCard(item = item, onOpen = onOpen, shape = shape)
        }
    }
}

/** 画布 R2-2：一条轮播，第一张（最急的那件）最宽、带箭头钮，其余窄卡。给画廊当备选。 */
@Composable
fun AttentionCarousel(
    summary: AttentionSummary,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (summary.isEmpty) return
    val items = listOfNotNull(summary.urgent) + summary.others
    Column(modifier.fillMaxWidth()) {
        AttentionHeader(count = items.size)
        LazyRow(
            contentPadding = PaddingValues(horizontal = SectionPadding),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            itemsIndexed(items, key = { index, item -> "${item.accountId}-${item.providerId}-$index" }) { index, item ->
                AttentionCard(
                    item = item,
                    onOpen = onOpen,
                    shape = RoundedCornerShape(Outer),
                    width = if (index == 0) 232.dp else 128.dp,
                    height = 200.dp,
                    prominent = index == 0,
                )
            }
        }
    }
}

@Composable
private fun AttentionCard(
    item: AttentionItem,
    onOpen: (String) -> Unit,
    shape: Shape,
    width: Dp = 164.dp,
    height: Dp = 150.dp,
    prominent: Boolean = false,
) {
    val (container, content) = attentionColors(item)
    val figure = attentionFigure(item)
    val label = attentionLabel(item)
    val sentence = attentionSentence(item)
    val target = item.target
    Surface(
        onClick = { target?.let(onOpen) },
        enabled = target != null,
        color = container,
        contentColor = content,
        shape = shape,
        modifier = Modifier
            .width(width)
            .height(height)
            .semantics { contentDescription = sentence },
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ServiceGlyph(name = item.displayName, colorKey = item.providerId, size = 28.dp)
                Spacer(Modifier.weight(1f))
                if (prominent && item.isUrgent) {
                    SymbolIcon(MaterialSymbol.Warning, contentDescription = null, filled = true)
                }
            }
            Spacer(Modifier.weight(1f))
            Text(
                figure,
                style = heroAmountTextStyle(if (prominent) 52.sp else 40.sp),
                maxLines = 1,
            )
            Spacer(Modifier.height(4.dp))
            Text(label, style = MaterialTheme.typography.bodySmall, maxLines = 2)
        }
    }
}

@Composable
private fun attentionColors(item: AttentionItem): TonePair {
    val scheme = MaterialTheme.colorScheme
    return when (item) {
        is AttentionItem.Anomaly -> TonePair(scheme.errorContainer, scheme.onErrorContainer)
        is AttentionItem.Balance -> TonePair(scheme.tertiaryContainer, scheme.onTertiaryContainer)
        is AttentionItem.Quota -> TonePair(scheme.primaryContainer, scheme.onPrimaryContainer)
    }
}

@Composable
private fun attentionFigure(item: AttentionItem): String = when (item) {
    is AttentionItem.Anomaly -> item.row.signedPercent
    is AttentionItem.Balance -> stringResource(R.string.dashboard_card_days, item.row.daysRemaining)
    is AttentionItem.Quota -> "${item.row.usedPercent}%"
}

@Composable
private fun attentionLabel(item: AttentionItem): String = when (item) {
    is AttentionItem.Anomaly -> stringResource(R.string.dashboard_card_anomaly, item.displayName)
    is AttentionItem.Balance -> stringResource(R.string.dashboard_card_balance, item.displayName)
    is AttentionItem.Quota -> stringResource(R.string.dashboard_card_quota, item.displayName)
}

@Composable
private fun attentionSentence(item: AttentionItem): String = when (item) {
    is AttentionItem.Anomaly -> stringResource(
        R.string.dashboard_urgent_anomaly,
        item.displayName,
        item.row.signedPercent.removePrefix("+"),
    )
    is AttentionItem.Balance -> stringResource(R.string.dashboard_urgent_balance, item.displayName, item.row.daysRemaining)
    is AttentionItem.Quota -> stringResource(R.string.dashboard_urgent_quota, item.displayName, item.row.usedPercent)
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardAttentionSectionPreview() {
    TollCatTheme {
        Column(verticalArrangement = Arrangement.spacedBy(24.dp), modifier = Modifier.padding(vertical = 16.dp)) {
            val summary = AttentionSummary.from(DashboardPreviewData.snapshot, DashboardModules.attention)
            DashboardAttentionSection(summary = summary, onOpen = {})
            AttentionCarousel(summary = summary, onOpen = {})
        }
    }
}
