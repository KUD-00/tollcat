@file:OptIn(
    androidx.compose.material3.ExperimentalMaterial3Api::class,
    androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class,
)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.BudgetRow
import com.zhechengqi.tollcat.CategorySliceRow
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.HeatmapMonthRow
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.PinnedServiceRow
import com.zhechengqi.tollcat.ProviderGlyph
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SubscriptionModuleItem
import com.zhechengqi.tollcat.SubscriptionsModuleRow
import com.zhechengqi.tollcat.SuperlativeRow
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.services.categoryTitleRes
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.LocalTollCatColors
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import kotlin.math.abs

private const val HeatmapPeakDayLimit = 5
private const val SubscriptionCardRowLimit = 3

@Composable
fun HeatmapModuleView(
    months: List<HeatmapMonthRow>,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (months.isEmpty()) return
    var index by remember(months) { mutableIntStateOf(months.lastIndex.coerceAtLeast(0)) }
    val month = months.getOrNull(index) ?: return
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen)
            .pointerInput(months.size) {
                var acc = 0f
                detectHorizontalDragGestures(
                    onDragEnd = {
                        if (abs(acc) >= 48f) {
                            index = (index + if (acc < 0) 1 else -1).coerceIn(0, months.lastIndex)
                        }
                        acc = 0f
                    },
                    onHorizontalDrag = { _, dragAmount -> acc += dragAmount },
                )
            },
    ) {
        Column(Modifier.padding(MeterSpacing.lg), verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm)) {
            ModuleHeader(stringResource(R.string.module_heatmap))
            Text(month.monthTitle, style = MaterialTheme.typography.titleLarge)
            HeatmapGrid(month)
            Text(month.totalText, style = MaterialTheme.typography.bodyLarge)
            if (month.peakCaption.isNotBlank()) {
                Text(
                    month.peakCaption,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
fun HeatmapGrid(month: HeatmapMonthRow, modifier: Modifier = Modifier) {
    val peak = month.values.filterNotNull().maxOrNull()?.takeIf { it > 0 } ?: 1.0
    val color = MaterialTheme.colorScheme.primary
    val empty = MaterialTheme.colorScheme.surfaceVariant
    // 未来日淡淡画出来，整月的形状才在；透明格会把月末挖掉。
    val future = empty.copy(alpha = 0.4f)
    val weeks = ((month.leadingEmptyDays + month.values.size + 6) / 7).coerceAtLeast(1)
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val gap = 3.dp
        val cell = ((maxWidth - gap * (weeks - 1).coerceAtLeast(0)) / weeks).coerceIn(8.dp, 18.dp)
        Canvas(
            Modifier
                .height(cell * 7 + gap * 6)
                .width(cell * weeks + gap * (weeks - 1)),
        ) {
            val cellPx = cell.toPx()
            val gapPx = gap.toPx()
            month.values.forEachIndexed { index, value ->
                val slot = month.leadingEmptyDays + index
                val week = slot / 7
                val day = slot % 7
                val fill = when {
                    value == null -> future
                    value <= 0.0 -> empty
                    else -> {
                        val ratio = value / peak
                        val level = when {
                            ratio > 0.75 -> 1f
                            ratio > 0.5 -> 0.75f
                            ratio > 0.25 -> 0.5f
                            else -> 0.3f
                        }
                        color.copy(alpha = level)
                    }
                }
                drawRoundRect(
                    color = fill,
                    topLeft = Offset(week * (cellPx + gapPx), day * (cellPx + gapPx)),
                    size = Size(cellPx, cellPx),
                    cornerRadius = CornerRadius(3.dp.toPx()),
                )
            }
        }
    }
}

@Composable
fun CategoriesModuleView(
    slices: List<CategorySliceRow>,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (slices.isEmpty()) return
    val rows = categoryDonutRows(slices)
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen),
    ) {
        Column(Modifier.padding(MeterSpacing.lg), verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm)) {
            ModuleHeader(stringResource(R.string.module_categories))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.md),
            ) {
                CompositionDonut(slices = rows, diameter = MeterSpacing.donut)
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                ) {
                    rows.forEachIndexed { index, row ->
                        CategoryLegendRow(row = row, index = index)
                    }
                }
            }
        }
    }
}

@Composable
private fun CategoryLegendRow(row: CompositionRow, index: Int) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
    ) {
        Box(
            Modifier
                .size(MeterSpacing.compositionSwatch)
                .clip(CircleShape)
                .background(CompositionTones.color(index, isOther = row.providerId == "other")),
        )
        Text(
            row.displayName,
            style = MaterialTheme.typography.bodyLarge,
            maxLines = 1,
            modifier = Modifier.weight(1f),
        )
        if (row.amount.isNotBlank()) {
            Text(
                row.amount,
                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
            )
        }
    }
}

@Composable
fun BudgetModuleView(
    budget: BudgetRow,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    val percentColor = when {
        budget.isOver -> MaterialTheme.colorScheme.error
        budget.isClose -> MaterialTheme.colorScheme.tertiary
        else -> MaterialTheme.colorScheme.onSurface
    }
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(MeterSpacing.lg), verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs)) {
            Text(stringResource(R.string.module_budget), style = MaterialTheme.typography.titleLargeEmphasized)
            Text(
                "${budget.usedPercent}%",
                style = MaterialTheme.typography.displaySmallEmphasized.copy(fontFeatureSettings = "tnum"),
                color = percentColor,
                fontWeight = FontWeight.SemiBold,
            )
            BudgetBlocks(
                fraction = budget.fraction,
                isOver = budget.isOver,
                isClose = budget.isClose,
            )
            Text(
                "${budget.spentText} / ${budget.budgetText}",
                style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
            )
        }
    }
}

@Composable
fun SuperlativesModuleView(
    items: List<SuperlativeRow>,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (items.isEmpty()) return
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(vertical = MeterSpacing.xs)) {
            Text(
                stringResource(R.string.module_superlatives),
                style = MaterialTheme.typography.titleLargeEmphasized,
                modifier = Modifier.padding(horizontal = MeterSpacing.lg, vertical = MeterSpacing.sm),
            )
            items.forEach { item ->
                DashboardInsightRow(
                    title = item.displayName,
                    subtitle = superlativeKind(item.kind),
                    trailingText = superlativeValue(item),
                    spokenLabel = "${superlativeKind(item.kind)} ${item.displayName} ${superlativeValue(item)}",
                    glyphKey = item.colorKey.ifBlank { item.providerId },
                    onClick = dashboardOpenAction(item.accountId, item.providerId, onOpen),
                )
            }
        }
    }
}

@Composable
fun PinnedServicesModuleView(
    items: List<PinnedServiceRow>,
    onOpen: (String) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (items.isEmpty()) return
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(vertical = MeterSpacing.xs)) {
            Text(
                stringResource(R.string.module_pinned),
                style = MaterialTheme.typography.titleLargeEmphasized,
                modifier = Modifier.padding(horizontal = MeterSpacing.lg, vertical = MeterSpacing.sm),
            )
            items.forEach { item ->
                PinnedServiceRowView(item = item, onOpen = onOpen)
            }
        }
    }
}

@Composable
private fun PinnedServiceRowView(item: PinnedServiceRow, onOpen: (String) -> Unit) {
    val change = item.changeText
    val changeColor = if (item.changeIsUp) {
        LocalTollCatColors.current.spendUp.main
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }
    val spoken = listOf(item.displayName, item.amountText, change.orEmpty())
        .filter { it.isNotBlank() }
        .joinToString(" ")
    val action = dashboardOpenAction(item.accountId, item.providerId, onOpen)
    ListItem(
        headlineContent = { Text(item.displayName, style = MaterialTheme.typography.titleMedium) },
        supportingContent = if (change == null) {
            null
        } else {
            {
                Text(change, style = MaterialTheme.typography.bodyMedium, color = changeColor)
            }
        },
        leadingContent = {
            ProviderGlyph(item.displayName, colorKey = item.colorKey.ifBlank { item.providerId })
        },
        trailingContent = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
            ) {
                if (item.spark.size >= 2) {
                    Sparkline(values = item.spark)
                }
                Text(
                    item.amountText,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontWeight = FontWeight.Medium,
                        fontFeatureSettings = "tnum",
                    ),
                )
            }
        },
        colors = ListItemDefaults.colors(containerColor = Color.Transparent),
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = MeterSpacing.minTap)
            .then(if (action != null) Modifier.clickable(onClick = action) else Modifier)
            .semantics { contentDescription = spoken },
    )
}

@Composable
fun SubscriptionsModuleCard(
    module: SubscriptionsModuleRow?,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (module == null || module.items.isEmpty()) return
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen),
    ) {
        Column(Modifier.padding(MeterSpacing.lg), verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm)) {
            ModuleHeader(stringResource(R.string.module_subscriptions))
            Text(module.monthlyTotalText, style = MaterialTheme.typography.headlineSmallEmphasized)
            module.items.take(SubscriptionCardRowLimit).forEach { item ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
                ) {
                    ProviderGlyph(
                        item.name,
                        colorKey = item.colorKey.ifBlank { item.providerId },
                    )
                    Text(
                        subscriptionTitle(item),
                        style = MaterialTheme.typography.bodyLarge,
                        maxLines = 1,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        item.amountText,
                        style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Composable
fun SubscriptionsDetailView(
    items: List<SubscriptionModuleItem>,
    onBack: () -> Unit,
    onOpen: ((String) -> Unit)? = null,
    monthlyTotalText: String = "",
    countCaption: String = "",
    nextChargeCaption: String? = null,
) {
    SettingsScaffold(title = stringResource(R.string.module_subscriptions), onBack = onBack) { inner ->
        Column(
            Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(MeterSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
        ) {
            if (monthlyTotalText.isNotBlank() || countCaption.isNotBlank() || !nextChargeCaption.isNullOrBlank()) {
                Surface(
                    color = MaterialTheme.colorScheme.surfaceContainer,
                    shape = MaterialTheme.shapes.extraLarge,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(
                        Modifier.padding(MeterSpacing.lg),
                        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs),
                    ) {
                        if (monthlyTotalText.isNotBlank()) {
                            AmountText(
                                text = monthlyTotalText,
                                style = MaterialTheme.typography.displaySmallEmphasized,
                            )
                        }
                        if (countCaption.isNotBlank()) {
                            Text(
                                countCaption,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        nextChargeCaption?.takeIf { it.isNotBlank() }?.let { caption ->
                            Text(
                                caption,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
            items.forEach { item ->
                DashboardInsightRow(
                    title = subscriptionTitle(item),
                    subtitle = item.periodCaption,
                    trailingText = item.amountText,
                    spokenLabel = "${subscriptionTitle(item)} ${item.amountText} ${item.periodCaption}",
                    glyphKey = item.colorKey.ifBlank { item.providerId },
                    onClick = onOpen?.let { open ->
                        dashboardOpenAction(item.accountId, item.providerId, open)
                    },
                )
            }
        }
    }
}

@Composable
fun SubscriptionsDetailView(
    module: SubscriptionsModuleRow,
    onBack: () -> Unit,
    onOpen: ((String) -> Unit)? = null,
) {
    SubscriptionsDetailView(
        items = module.items,
        onBack = onBack,
        onOpen = onOpen,
        monthlyTotalText = module.monthlyTotalText,
        countCaption = module.countCaption,
        nextChargeCaption = module.nextChargeCaption,
    )
}

@Composable
fun HeatmapDetailView(months: List<HeatmapMonthRow>, onBack: () -> Unit) {
    val totalLabel = stringResource(R.string.dashboard_scope_total)
    SettingsScaffold(title = stringResource(R.string.module_heatmap), onBack = onBack) { inner ->
        Column(
            Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(MeterSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.lg),
        ) {
            months.asReversed().forEach { month ->
                Column(verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm)) {
                    Text(month.title, style = MaterialTheme.typography.titleMedium)
                    HeatmapGrid(month)
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(totalLabel, style = MaterialTheme.typography.bodyLarge)
                        Text(
                            month.totalText,
                            style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    if (month.peakCaption.isNotBlank()) {
                        Text(
                            month.peakCaption,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    heatmapPeakDays(month).forEach { peak ->
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(peak.label, style = MaterialTheme.typography.bodyLarge)
                            Text(
                                peak.amountText,
                                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CategoriesDetailView(slices: List<CategorySliceRow>, onBack: () -> Unit) {
    val rows = categoryDonutRows(slices)
    SettingsScaffold(title = stringResource(R.string.module_categories), onBack = onBack) { inner ->
        Column(
            Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(MeterSpacing.md),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        ) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                CompositionDonut(slices = rows)
            }
            slices.forEachIndexed { index, slice ->
                val title = stringResource(categoryTitleRes(slice.category))
                Column(verticalArrangement = Arrangement.spacedBy(MeterSpacing.xxs)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                    ) {
                        Box(
                            Modifier
                                .size(MeterSpacing.compositionSwatch)
                                .clip(CircleShape)
                                .background(CompositionTones.color(index)),
                        )
                        Text(title, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                        if (slice.amountText.isNotBlank()) {
                            Text(
                                slice.amountText,
                                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        Text(
                            "${slice.percent}%",
                            style = MaterialTheme.typography.bodyMedium.copy(fontFeatureSettings = "tnum"),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    if (slice.memberNames.isNotEmpty()) {
                        Text(
                            slice.memberNames.joinToString("、"),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(start = MeterSpacing.compositionSwatch + MeterSpacing.xs),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ModuleHeader(title: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLargeEmphasized,
            modifier = Modifier.weight(1f),
        )
        SymbolIcon(
            MaterialSymbol.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun superlativeKind(kind: String): String = stringResource(
    when (kind) {
        "biggestShare" -> R.string.superlative_share
        "biggestRise" -> R.string.superlative_rise
        else -> R.string.superlative_stale
    },
)

@Composable
private fun superlativeValue(item: SuperlativeRow): String {
    if (item.kind != "stalest") return item.value
    val days = item.value.toIntOrNull() ?: return item.value
    return if (days <= 0) {
        stringResource(R.string.relative_today)
    } else {
        stringResource(R.string.settings_reminder_notice_days, days)
    }
}

@Composable
private fun categoryDonutRows(slices: List<CategorySliceRow>): List<CompositionRow> {
    return slices.map { slice ->
        CompositionRow(
            providerId = slice.category,
            displayName = stringResource(categoryTitleRes(slice.category)),
            colorKey = slice.colorKey,
            amount = slice.amountText,
            percent = slice.percent,
            fraction = slice.fraction,
        )
    }
}

private fun subscriptionTitle(item: SubscriptionModuleItem): String {
    return if (item.quantity > 1) "${item.name} ×${item.quantity}" else item.name
}

private data class HeatmapPeakDay(val label: String, val amountText: String)

private fun heatmapPeakDays(month: HeatmapMonthRow): List<HeatmapPeakDay> {
    return month.values
        .mapIndexedNotNull { index, value ->
            value?.takeIf { it > 0 }?.let { index to it }
        }
        .sortedByDescending { it.second }
        .take(HeatmapPeakDayLimit)
        .mapNotNull { (index, amount) ->
            val label = month.dayLabels.getOrNull(index)?.takeIf { it.isNotBlank() } ?: return@mapNotNull null
            HeatmapPeakDay(label, MoneyDisplay.formatUsd(amount.toString()))
        }
}

private val previewHeatmap = listOf(
    HeatmapMonthRow(
        monthStartMillis = 0,
        title = "2026年8月",
        monthTitle = "八月",
        values = (1..31).map { if (it > 20) null else (it % 7).toDouble() },
        leadingEmptyDays = 2,
        totalText = "$47.20",
        peakCaption = "花得最多：8月12日，$4.10",
        dayLabels = (1..31).map { "8月${it}日" },
    ),
    HeatmapMonthRow(
        monthStartMillis = 1,
        title = "2026年9月",
        monthTitle = "九月",
        values = (1..30).map { if (it > 3) null else it * 0.6 },
        leadingEmptyDays = 2,
        totalText = "$1.81",
        peakCaption = "花得最多：9月1日，$1.28",
        dayLabels = (1..30).map { "9月${it}日" },
    ),
)

private val previewPinned = listOf(
    PinnedServiceRow(
        accountId = "cf-1",
        providerId = "cloudflare",
        displayName = "Cloudflare",
        colorKey = "cloudflare",
        amountText = "$11.05",
        spark = listOf(6f, 8f, 7f, 9f, 10f, 11f),
        changeText = "+12%",
        changeIsUp = true,
    ),
    PinnedServiceRow(
        accountId = "neon-1",
        providerId = "neon",
        displayName = "Neon",
        colorKey = "neon",
        amountText = "$3.13",
        spark = listOf(0f, 0f, 2f, 3f, 3f, 3.1f),
        changeText = null,
        changeIsUp = false,
    ),
)

private val previewSubscriptions = SubscriptionsModuleRow(
    monthlyTotalText = "$24.00",
    countCaption = "2 笔，折算每月。年付按 12 摊。",
    nextChargeCaption = "下一笔：GitHub Team，9月12日",
    items = listOf(
        SubscriptionModuleItem("a", "GitHub Team", "$4.00", "每月", "gh-1", "github", "github", 1),
        SubscriptionModuleItem("b", "ChatGPT Plus", "$20.00", "每月", "oa-1", "openai", "openai", 1),
    ),
)

private val previewCategories = listOf(
    CategorySliceRow("hosting", "$21.40", 55, 0.55f, "aws", listOf("AWS", "Vercel")),
    CategorySliceRow("aiInference", "$7.62", 20, 0.20f, "openai", listOf("OpenAI")),
    CategorySliceRow("networkEdge", "$11.05", 25, 0.25f, "cloudflare", listOf("Cloudflare")),
)

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun ExtraModulesPreview() {
    TollCatTheme {
        Column(Modifier.padding(MeterSpacing.md), verticalArrangement = Arrangement.spacedBy(MeterSpacing.sm)) {
            HeatmapModuleView(months = previewHeatmap, onOpen = {})
            BudgetModuleView(
                BudgetRow("$21.40", "$40.00", "$18.60", "$0.00", 0.535f, usedPercent = 54, isOver = false, isClose = false),
            )
            BudgetModuleView(
                BudgetRow("$91.30", "$80.00", "$0.00", "$11.30", 1.14f, usedPercent = 114, isOver = true, isClose = true),
            )
            PinnedServicesModuleView(items = previewPinned, onOpen = {})
            CategoriesModuleView(slices = previewCategories, onOpen = {})
            SubscriptionsModuleCard(module = previewSubscriptions, onOpen = {})
        }
    }
}

@Preview(name = "Heatmap Detail Light", showBackground = true)
@Preview(name = "Heatmap Detail Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun HeatmapDetailViewPreview() {
    TollCatTheme {
        HeatmapDetailView(months = previewHeatmap, onBack = {})
    }
}

@Preview(name = "Categories Detail Light", showBackground = true)
@Preview(name = "Categories Detail Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CategoriesDetailViewPreview() {
    TollCatTheme {
        CategoriesDetailView(slices = previewCategories, onBack = {})
    }
}

@Preview(name = "Subscriptions Detail Light", showBackground = true)
@Preview(name = "Subscriptions Detail Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SubscriptionsDetailViewPreview() {
    TollCatTheme {
        SubscriptionsDetailView(module = previewSubscriptions, onBack = {}, onOpen = {})
    }
}
