package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.ComparisonItemRow
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.LocalTollCatColors
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

/**
 * 较上月同期的追查页。主角柱含还不能比的本月金额；
 * 缺同期的另开一节，行上不当 $0、不编百分比。
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ComparisonDetailView(
    dashboard: DashboardSnapshot,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    onOpen: ((String) -> Unit)? = null,
) {
    val currentLabel = stringResource(R.string.dashboard_comparison_this_month)
    val previousLabel = stringResource(R.string.dashboard_comparison_last_month)
    val unavailable = stringResource(R.string.dashboard_comparison_unavailable)
    val content = ComparisonContent.from(
        dashboard = dashboard,
        currentLabel = currentLabel,
        previousLabel = previousLabel,
        unavailableCaption = unavailable,
    ) ?: ComparisonContent(
        percentText = "—",
        caption = unavailable,
        spokenLabel = unavailable,
        currentWeight = 1f,
        previousWeight = 1f,
        currentLabel = currentLabel,
        previousLabel = previousLabel,
        tone = ComparisonContent.Tone.Unknown,
    )
    val currentAmount = dashboard.formattedVariable.ifBlank { dashboard.formattedTotal }
        .takeIf { it.isNotBlank() && it != "—" }
    val previousAmount = dashboard.formattedComparison
    val comparable = dashboard.comparisonItems.filter { it.isComparable }
    val incomparable = dashboard.comparisonItems.filter { !it.isComparable }
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.module_comparison)) },
                navigationIcon = {
                    IconButton(
                        onClick = onBack,
                        shapes = IconButtonDefaults.shapes(),
                    ) {
                        SymbolIcon(
                            MaterialSymbol.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                },
            )
        },
    ) { inner ->
        LazyColumn(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize(),
            contentPadding = PaddingValues(horizontal = MeterSpacing.md, vertical = MeterSpacing.xs),
            verticalArrangement = Arrangement.spacedBy(Bento.gap),
        ) {
            item {
                ComparisonDetailHero(
                    content = content,
                    modifier = Modifier.clip(Bento.top),
                )
            }
            if (comparable.isNotEmpty()) {
                itemsIndexed(comparable, key = { _, item -> "c-${item.accountId}-${item.providerId}-${item.displayName}" }) { index, item ->
                    ComparisonAccountRow(
                        item = item,
                        currentLabel = currentLabel,
                        previousLabel = previousLabel,
                        unavailable = unavailable,
                        onOpen = onOpen,
                        modifier = Modifier.clip(
                            Bento.groupShape(first = index == 0, last = index == comparable.lastIndex),
                        ),
                    )
                }
            }
            if (incomparable.isNotEmpty()) {
                item {
                    Text(
                        text = unavailable,
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(
                            start = MeterSpacing.xxs,
                            top = MeterSpacing.md,
                            bottom = MeterSpacing.xxs,
                        ),
                    )
                }
                itemsIndexed(incomparable, key = { _, item -> "i-${item.accountId}-${item.providerId}-${item.displayName}" }) { index, item ->
                    ComparisonAccountRow(
                        item = item,
                        currentLabel = currentLabel,
                        previousLabel = previousLabel,
                        unavailable = unavailable,
                        onOpen = onOpen,
                        modifier = Modifier.clip(
                            Bento.groupShape(first = index == 0, last = index == incomparable.lastIndex),
                        ),
                    )
                }
                item {
                    Text(
                        text = stringResource(R.string.dashboard_comparison_incomparable_footer),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(
                            start = MeterSpacing.xxs,
                            top = MeterSpacing.xs,
                            bottom = MeterSpacing.sm,
                        ),
                    )
                }
            }
            if (comparable.isEmpty() && incomparable.isEmpty() && (currentAmount != null || previousAmount != null)) {
                item {
                    ComparisonTotalsCard(
                        currentLabel = currentLabel,
                        previousLabel = previousLabel,
                        currentAmount = currentAmount,
                        previousAmount = previousAmount,
                        currentSubtitle = dashboard.periodCaption.ifBlank { dashboard.monthTitle },
                        previousSubtitle = content.caption,
                        shape = Bento.bottom,
                    )
                }
            }
        }
    }
}

@Composable
private fun ComparisonAccountRow(
    item: ComparisonItemRow,
    currentLabel: String,
    previousLabel: String,
    unavailable: String,
    onOpen: ((String) -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val subtitle = if (item.isComparable) {
        val previous = item.previousText.orEmpty()
        "$currentLabel ${item.currentText} · $previousLabel $previous".trim()
    } else {
        unavailable
    }
    val trailing = if (item.isComparable) {
        item.signedPercent ?: item.currentText
    } else {
        item.currentText
    }
    val trailingColor = when {
        !item.isComparable -> MaterialTheme.colorScheme.onSurfaceVariant
        (item.changeRatio ?: 0.0) > 0 -> LocalTollCatColors.current.spendUp.main
        (item.changeRatio ?: 0.0) < 0 -> LocalTollCatColors.current.spendDown.main
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    val hint = stringResource(R.string.dashboard_view_provider, item.displayName)
    DashboardInsightRow(
        title = item.displayName,
        subtitle = subtitle,
        trailingText = trailing,
        spokenLabel = "${item.displayName}，$trailing，$subtitle",
        trailingColor = trailingColor,
        glyphKey = item.colorKey.ifBlank { item.providerId },
        onClick = onOpen?.let { open -> dashboardOpenAction(item.accountId, item.providerId, open) },
        modifier = modifier
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .semantics { contentDescription = hint },
    )
}

@Composable
private fun ComparisonDetailHero(
    content: ComparisonContent,
    modifier: Modifier = Modifier,
) {
    val percentColor = when (content.tone) {
        ComparisonContent.Tone.Up -> LocalTollCatColors.current.spendUp.main
        ComparisonContent.Tone.Down -> LocalTollCatColors.current.spendDown.main
        ComparisonContent.Tone.Flat, ComparisonContent.Tone.Unknown -> MaterialTheme.colorScheme.onSurface
    }
    val symbol = when (content.tone) {
        ComparisonContent.Tone.Up -> MaterialSymbol.TrendingUp
        ComparisonContent.Tone.Down -> MaterialSymbol.TrendingDown
        ComparisonContent.Tone.Flat, ComparisonContent.Tone.Unknown -> MaterialSymbol.TrendingFlat
    }
    val percentStyle = MaterialTheme.typography.displaySmall.copy(
        fontWeight = FontWeight.SemiBold,
        fontFeatureSettings = "tnum",
    )
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = content.spokenLabel },
    ) {
        Column(
            modifier = Modifier.padding(MeterSpacing.lg),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
            ) {
                SymbolIcon(symbol, contentDescription = null, size = MeterSpacing.providerGlyph)
                Text(text = content.percentText, style = percentStyle, color = percentColor, maxLines = 1)
            }
            Text(
                text = content.caption,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            ComparisonBars(content)
        }
    }
}

@Composable
private fun ComparisonTotalsCard(
    currentLabel: String,
    previousLabel: String,
    currentAmount: String?,
    previousAmount: String?,
    currentSubtitle: String,
    previousSubtitle: String,
    shape: androidx.compose.ui.graphics.Shape,
) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(vertical = MeterSpacing.xs)) {
            if (currentAmount != null) {
                DashboardInsightRow(
                    title = currentLabel,
                    subtitle = currentSubtitle,
                    trailingText = currentAmount,
                    spokenLabel = "$currentLabel，$currentAmount",
                    modifier = Modifier.background(MaterialTheme.colorScheme.surfaceContainer),
                )
            }
            if (previousAmount != null) {
                DashboardInsightRow(
                    title = previousLabel,
                    subtitle = previousSubtitle,
                    trailingText = previousAmount,
                    spokenLabel = "$previousLabel，$previousAmount",
                    modifier = Modifier.background(MaterialTheme.colorScheme.surfaceContainer),
                )
            }
        }
    }
}

private val previewComparisonItems = listOf(
    ComparisonItemRow(
        accountId = "aws-1",
        providerId = "aws",
        displayName = "AWS",
        colorKey = "aws",
        currentText = "$21.40",
        previousText = "$13.20",
        signedPercent = "+62%",
        changeRatio = 0.62,
        isComparable = true,
    ),
    ComparisonItemRow(
        accountId = "cf-1",
        providerId = "cloudflare",
        displayName = "Cloudflare",
        colorKey = "cloudflare",
        currentText = "$11.05",
        previousText = "$9.80",
        signedPercent = "+13%",
        changeRatio = 0.13,
        isComparable = true,
    ),
    ComparisonItemRow(
        accountId = "neon-1",
        providerId = "neon",
        displayName = "Neon",
        colorKey = "neon",
        currentText = "$3.13",
        previousText = null,
        signedPercent = null,
        changeRatio = null,
        isComparable = false,
    ),
)

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ComparisonDetailViewPreview() {
    TollCatTheme {
        ComparisonDetailView(
            dashboard = DashboardPreviewData.snapshot.copy(comparisonItems = previewComparisonItems),
            onBack = {},
            onOpen = {},
        )
    }
}

@Preview(name = "Unknown Light", showBackground = true)
@Preview(name = "Unknown Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ComparisonDetailViewUnknownPreview() {
    TollCatTheme {
        ComparisonDetailView(
            dashboard = DashboardPreviewData.snapshot.copy(
                formattedComparison = null,
                changePercent = null,
                comparisonPercentText = "—",
                comparisonCaption = "还不能对比",
                comparisonTone = "unknown",
                comparisonItems = previewComparisonItems.filter { !it.isComparable },
            ),
            onBack = {},
            onOpen = {},
        )
    }
}
