package com.zhechengqi.tollcat.services

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.dashboard.CompositionDonut
import com.zhechengqi.tollcat.ui.AmountText
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import com.zhechengqi.tollcat.ui.bentoRowColors
import com.zhechengqi.tollcat.ui.symbols.MaterialSymbol
import com.zhechengqi.tollcat.ui.symbols.SymbolIcon
import java.math.RoundingMode

/**
 * 分组和金额都由桥算（`ProductSpendBreakdown` → `MeterCore/SpendGrouping`）；
 * 这里只把值填进 Android 的句子模板。
 */
@Composable
fun rememberSpendBreakdown(
    linesJson: String?,
    grouping: SpendBreakdownGrouping,
): SpendBreakdownContent {
    val context = LocalContext.current
    val currency = MoneyDisplay.currency
    val locale = LocalConfiguration.current.locales[0].toLanguageTag()
    return remember(linesJson, grouping, currency, locale) {
        if (linesJson.isNullOrBlank()) {
            SpendBreakdownContent.empty
        } else {
            SpendBreakdownDecoder.decode(
                json = MeterCoreNative.spendBreakdownJson(linesJson, grouping.raw, currency, locale),
                otherTitle = context.getString(R.string.category_other),
                allowance = { amount -> context.getString(R.string.services_spend_allowance, amount) },
                listPrice = { amount -> context.getString(R.string.services_spend_list, amount) },
                discount = { list, saved ->
                    context.getString(R.string.services_spend_discount, list, saved)
                },
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SpendBreakdownScreen(
    snapshots: List<SnapshotRow>,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    SpendBreakdownScreen(
        linesJson = remember(snapshots) { SpendLines.latestJson(snapshots) },
        onBack = onBack,
        modifier = modifier,
    )
}

@JvmName("SpendBreakdownFromLines")
@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SpendBreakdownScreen(
    linesJson: String?,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var grouping by rememberSaveable { mutableStateOf(SpendBreakdownGrouping.Category) }
    val content = rememberSpendBreakdown(linesJson, grouping)
    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.services_spend_where)) },
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
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(Bento.gap),
        ) {
            item {
                SpendBreakdownSummary(content)
            }
            if (content.supportsScopeGrouping) {
                item {
                    Text(
                        text = stringResource(R.string.services_spend_group),
                        style = MaterialTheme.typography.titleMediumEmphasized,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(start = 4.dp, top = 12.dp, bottom = 8.dp),
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(
                            ButtonGroupDefaults.ConnectedSpaceBetween,
                        ),
                    ) {
                        SpendGrouping.entries.forEachIndexed { index, item ->
                            ToggleButton(
                                checked = grouping == item.value,
                                onCheckedChange = { checked -> if (checked) grouping = item.value },
                                modifier = Modifier.weight(1f),
                                shapes = when (index) {
                                    0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                                    else -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                                },
                            ) {
                                Text(stringResource(item.labelRes), maxLines = 1)
                            }
                        }
                    }
                }
            }
            item {
                BentoGroup {
                    content.groups.forEachIndexed { index, group ->
                        Surface(
                            color = MaterialTheme.colorScheme.surfaceContainer,
                            shape = Bento.middle,
                        ) {
                            SpendBreakdownRow(group = group, index = index)
                        }
                        if (group.items.size > 1) {
                            group.items.forEach { item ->
                                Surface(
                                    color = MaterialTheme.colorScheme.surfaceContainer,
                                    shape = Bento.middle,
                                ) {
                                    SpendBreakdownItemRow(item)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SpendBreakdownPreviewSection(
    content: SpendBreakdownContent,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (content.isEmpty) return
    val preview = content.previewGroups
    Column(modifier = modifier.fillMaxWidth()) {
        BentoGroup {
            preview.forEachIndexed { index, group ->
                Surface(color = MaterialTheme.colorScheme.surfaceContainer, shape = Bento.middle) {
                    SpendBreakdownRow(group = group, index = index, compact = true)
                }
            }
            if (content.itemCount > preview.size) {
                ListItem(
                    onClick = onOpen,
                    trailingContent = {
                        SymbolIcon(
                            MaterialSymbol.KeyboardArrowRight,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                        )
                    },
                    modifier = Modifier.clip(Bento.middle),
                    colors = bentoRowColors(),
                    content = {
                        Text(
                            text = stringResource(
                                R.string.services_spend_all_items,
                                content.itemCount,
                            ),
                            color = MaterialTheme.colorScheme.primary,
                        )
                    },
                )
            }
        }
        content.discountCaption?.let { discount ->
            Text(
                text = discount,
                style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SpendBreakdownSummary(content: SpendBreakdownContent) {
    val slices = content.groups.mapIndexed { index, group ->
        CompositionRow(
            providerId = if (group.id == "__other__") "other" else group.id,
            displayName = group.title,
            colorKey = "",
            amount = group.amountCaption,
            percent = (group.fraction * 100).toInt(),
            fraction = group.fraction.toFloat(),
        )
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .semantics { contentDescription = content.spokenSummary },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            AmountText(
                text = content.totalCaption,
                style = MaterialTheme.typography.displaySmallEmphasized,
            )
            content.discountCaption?.let { discount ->
                Text(
                    text = discount,
                    style = MaterialTheme.typography.bodySmall.copy(fontFeatureSettings = "tnum"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        if (slices.isNotEmpty()) {
            CompositionDonut(slices = slices, diameter = 96.dp, strokeWidth = 12.dp)
        }
    }
}

/** 预览用。`.so` 没装上时解码回空内容，这里只验版式。 */
private const val PREVIEW_LINES = """[
  {"category":"actions","label":"Actions Linux","scope":"RelayOS","amountUSD":"4.00"},
  {"category":"actions","label":"Actions storage","scope":"RelayOS","amountUSD":"1.00"},
  {"category":"copilot","label":"Copilot Business","amountUSD":"19.00"}
]"""

private enum class SpendGrouping(val value: SpendBreakdownGrouping, val labelRes: Int) {
    Category(SpendBreakdownGrouping.Category, R.string.services_spend_by_category),
    Scope(SpendBreakdownGrouping.Scope, R.string.services_spend_by_scope),
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun SpendBreakdownScreenPreview() {
    TollCatTheme {
        SpendBreakdownScreen(
            linesJson = PREVIEW_LINES,
            onBack = {},
        )
    }
}
