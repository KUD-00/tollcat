package com.zhechengqi.tollcat.services

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ButtonGroupDefaults
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.ui.Bento
import com.zhechengqi.tollcat.ui.BentoGroup
import com.zhechengqi.tollcat.ui.bentoRowColors

enum class HistoryRange(val millis: Long, val key: String) {
    Days7(7L * 24 * 60 * 60 * 1000, "days7"),
    Days30(30L * 24 * 60 * 60 * 1000, "days30"),
    Months12(365L * 24 * 60 * 60 * 1000, "months12"),
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ProviderHistory(
    snapshots: List<SnapshotRow>,
    chart: HistoryChartState,
    range: HistoryRange,
    onRange: (HistoryRange) -> Unit,
    showRangePicker: Boolean = true,
    modifier: Modifier = Modifier,
    nowMillis: Long = System.currentTimeMillis(),
) {
    val now = nowMillis
    val visible = snapshots.filter { now - it.fetchedAtMillis <= range.millis }
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (showRangePicker) {
            Text(
                text = stringResource(R.string.services_history_range),
                style = MaterialTheme.typography.titleMediumEmphasized,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 4.dp),
            )
            // 老 SegmentedButton 退役，换 M3E 的 connected ToggleButton 组（选中形变 + 填色）。
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(ButtonGroupDefaults.ConnectedSpaceBetween),
            ) {
                HistoryRange.entries.forEachIndexed { index, item ->
                    ToggleButton(
                        checked = range == item,
                        onCheckedChange = { checked -> if (checked) onRange(item) },
                        modifier = Modifier.weight(1f),
                        shapes = when (index) {
                            0 -> ButtonGroupDefaults.connectedLeadingButtonShapes()
                            HistoryRange.entries.lastIndex -> ButtonGroupDefaults.connectedTrailingButtonShapes()
                            else -> ButtonGroupDefaults.connectedMiddleButtonShapes()
                        },
                    ) {
                        Text(
                            stringResource(
                                when (item) {
                                    HistoryRange.Days7 -> R.string.services_history_7
                                    HistoryRange.Days30 -> R.string.services_history_30
                                    HistoryRange.Months12 -> R.string.services_history_12
                                },
                            ),
                            maxLines = 1,
                        )
                    }
                }
            }
        }
        if (visible.isEmpty()) {
            Text(
                text = stringResource(R.string.services_no_reading),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(vertical = 8.dp),
            )
        } else {
            Text(
                text = stringResource(R.string.services_history),
                style = MaterialTheme.typography.titleMediumEmphasized,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 8.dp, start = 4.dp),
            )
            BentoGroup {
                when (chart) {
                    is HistoryChartState.Spend -> {
                        if (chart.points.isNotEmpty() || showRangePicker) {
                            HistoryChartCard {
                                if (chart.points.isEmpty()) {
                                    Text(
                                        text = stringResource(R.string.services_chart_spend_empty),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    )
                                } else {
                                    val spoken = stringResource(
                                        R.string.services_chart_spend_a11y,
                                        chart.points.size,
                                    )
                                    SpendBarChart(
                                        content = chart,
                                        modifier = Modifier.semantics { contentDescription = spoken },
                                        visibleSlotCount = range.visibleSlotCount(),
                                    )
                                    if (chart.isIntervalSpend) {
                                        Text(
                                            text = stringResource(R.string.services_chart_mtd_note),
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                                            modifier = Modifier.padding(top = 8.dp),
                                        )
                                    }
                                }
                            }
                        }
                    }
                    is HistoryChartState.Balance -> {
                        if (chart.points.isNotEmpty() || showRangePicker) {
                            HistoryChartCard {
                                if (chart.points.isEmpty()) {
                                    Text(
                                        text = stringResource(R.string.services_chart_balance_empty),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    )
                                } else {
                                    val spoken = stringResource(
                                        R.string.services_chart_balance_a11y,
                                        chart.points.size,
                                    )
                                    BalanceLineChart(
                                        content = chart,
                                        modifier = Modifier.semantics { contentDescription = spoken },
                                        visibleSlotCount = range.visibleSlotCount(),
                                    )
                                }
                            }
                        }
                    }
                    HistoryChartState.None -> Unit
                }
                visible.forEach { snapshot ->
                    ListItem(
                        supportingContent = {
                            Text(
                                historyAmount(snapshot),
                                style = MaterialTheme.typography.bodyLarge.copy(fontFeatureSettings = "tnum"),
                            )
                        },
                        modifier = Modifier.clip(Bento.middle),
                        colors = bentoRowColors(),
                        content = { Text(historyRelativeCaption(snapshot.fetchedAtMillis, now)) },
                    )
                }
            }
        }
    }
}

/** 图表的 bento 成员卡。 */
@Composable
private fun HistoryChartCard(content: @Composable () -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceContainer,
        shape = Bento.middle,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 16.dp)) {
            content()
        }
    }
}

private fun historyAmount(snapshot: SnapshotRow): String {
    snapshot.currentSpendUsd?.let { return formatMoney(it) }
    snapshot.committedMonthlyUsd?.let { return formatMoney(it) }
    snapshot.balanceUsd?.let { return formatMoney(it) }
    snapshot.freeQuotaUsedRatio?.let { return "${(it * 100).toInt()}%" }
    return "—"
}

/** 档位口径和 iOS `ServiceRelativeTime` 一致：刚刚 / <24h 相对时间 / 月日。 */
@Composable
private fun historyRelativeCaption(fetchedAt: Long, nowMillis: Long): String {
    val context = LocalContext.current
    return ServiceRelativeTime.caption(context, fetchedAt, nowMillis)
}
