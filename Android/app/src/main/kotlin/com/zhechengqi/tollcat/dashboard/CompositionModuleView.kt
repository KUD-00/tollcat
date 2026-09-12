@file:OptIn(androidx.compose.material3.ExperimentalMaterial3ExpressiveApi::class)

package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon

@Composable
fun CompositionModuleView(
    rows: List<CompositionRow>,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = MaterialTheme.shapes.extraLarge,
) {
    if (rows.isEmpty()) return
    val otherLabel = stringResource(R.string.dashboard_composition_other)
    val slices = compositionSlices(rows, otherLabel)
    val spoken = slices.joinToString("。") { "${it.displayName}，${it.amount}".trim('，') }
    val hint = stringResource(R.string.dashboard_composition_hint)
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = shape,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen)
            .semantics { contentDescription = "$spoken。$hint" },
    ) {
        Column(
            modifier = Modifier.padding(MeterSpacing.lg),
            verticalArrangement = Arrangement.spacedBy(MeterSpacing.md),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.module_composition),
                    style = MaterialTheme.typography.titleLargeEmphasized,
                    modifier = Modifier.weight(1f),
                )
                SymbolIcon(
                    MaterialSymbol.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.md),
            ) {
                CompositionDonut(slices = slices, diameter = MeterSpacing.donut)
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
                ) {
                    slices.forEachIndexed { index, row ->
                        CompositionLegendRow(row = row, index = index)
                    }
                }
            }
        }
    }
}

/** 分段条。段间留 2dp 缝——和 App 图标同一套「构成分段」语言，入场从左往右铺满。 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun CompositionBar(slices: List<CompositionRow>, modifier: Modifier = Modifier) {
    val spatial = MaterialTheme.motionScheme.defaultSpatialSpec<Float>()
    val entrance = remember { Animatable(0f) }
    LaunchedEffect(slices) {
        entrance.snapTo(0f)
        entrance.animateTo(1f, spatial)
    }
    val colors = slices.mapIndexed { index, row ->
        CompositionTones.color(index, isOther = row.providerId == "other")
    }
    Canvas(
        modifier
            .fillMaxWidth()
            .height(16.dp)
            .clip(MaterialTheme.shapes.small),
    ) {
        val gap = if (slices.size > 1) 2.dp.toPx() else 0f
        val available = size.width - gap * (slices.size - 1)
        val total = slices.sumOf { it.fraction.coerceAtLeast(0.01f).toDouble() }.toFloat()
        val reveal = size.width * entrance.value.coerceIn(0f, 1f)
        var x = 0f
        slices.forEachIndexed { index, row ->
            val width = available * (row.fraction.coerceAtLeast(0.01f) / total)
            val visible = (reveal - x).coerceIn(0f, width)
            if (visible > 0f) {
                drawRect(
                    color = colors[index],
                    topLeft = Offset(x, 0f),
                    size = Size(visible, size.height),
                )
            }
            x += width + gap
        }
    }
}

@Composable
private fun CompositionLegendRow(row: CompositionRow, index: Int) {
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
                fontWeight = FontWeight.Medium,
                maxLines = 1,
            )
        }
    }
}

fun compositionSlices(
    rows: List<CompositionRow>,
    otherLabel: String,
): List<CompositionRow> {
    if (rows.size <= CompositionTones.namedLimit) return rows
    val named = rows.take(CompositionTones.namedLimit)
    val rest = rows.drop(CompositionTones.namedLimit)
    val other = CompositionRow(
        providerId = "other",
        displayName = otherLabel,
        colorKey = "other",
        amount = summedAmount(rest),
        percent = rest.sumOf { it.percent }.coerceAtMost(100),
        fraction = rest.sumOf { it.fraction.toDouble() }.toFloat(),
    )
    return named + other
}

private fun summedAmount(rows: List<CompositionRow>): String {
    if (rows.isEmpty()) return ""
    if (rows.size == 1) return rows[0].amount
    val numbers = rows.map { row ->
        val compact = row.amount.replace(",", "").replace(" ", "")
        Regex("""-?\d+(?:\.\d+)?""").find(compact)?.value?.toDoubleOrNull()
    }
    if (numbers.any { it == null }) return ""
    val sum = numbers.filterNotNull().sum()
    return MoneyDisplay.formatUsd("%.2f".format(sum))
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionModuleViewPreview() {
    TollCatTheme {
        CompositionModuleView(
            rows = DashboardPreviewData.snapshot.composition,
            onOpen = {},
        )
    }
}

@Preview(name = "Other Light", showBackground = true)
@Preview(name = "Other Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun CompositionModuleViewOtherPreview() {
    TollCatTheme {
        CompositionModuleView(
            rows = DashboardPreviewData.snapshot.composition + listOf(
                CompositionRow("vercel", "Vercel", "vercel", "$2.00", 4, 0.04f),
                CompositionRow("fly", "Fly.io", "fly", "$1.50", 3, 0.03f),
            ),
            onOpen = {},
        )
    }
}
