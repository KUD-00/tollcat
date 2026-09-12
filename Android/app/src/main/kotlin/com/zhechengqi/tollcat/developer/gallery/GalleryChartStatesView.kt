package com.zhechengqi.tollcat.developer.gallery

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.services.BalanceLineChart
import com.zhechengqi.tollcat.services.ChartPoint
import com.zhechengqi.tollcat.services.HistoryChartState
import com.zhechengqi.tollcat.services.SpendBarChart
import java.util.Calendar

@Composable
fun GalleryChartStatesView(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val spend = remember { spendSamples() }
    val balance = remember { balanceSamples() }
    GalleryScaffold(title = stringResource(R.string.dev_gallery_charts), onBack = onBack, modifier = modifier) {
        spendBlock(stringResource(R.string.services_chart_spend_empty), spend[0])
        spendBlock(stringResource(R.string.dev_chart_one_day), spend[1])
        spendBlock(stringResource(R.string.dev_chart_month), spend[2])
        Text(
            stringResource(R.string.dev_chart_spend_note),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(16.dp))
        balanceBlock(stringResource(R.string.services_chart_balance_empty), balance[0])
        balanceBlock(stringResource(R.string.dev_chart_one_point), balance[1])
        balanceBlock(stringResource(R.string.dev_chart_line), balance[2])
        Text(
            stringResource(R.string.dev_chart_balance_note),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun spendBlock(title: String, chart: HistoryChartState.Spend) {
    Spacer(Modifier.height(12.dp))
    Text(title, style = MaterialTheme.typography.titleSmall)
    if (chart.points.isEmpty()) {
        Text(
            stringResource(R.string.services_chart_spend_empty),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    } else {
        SpendBarChart(content = chart)
    }
}

@Composable
private fun balanceBlock(title: String, chart: HistoryChartState.Balance) {
    Spacer(Modifier.height(12.dp))
    Text(title, style = MaterialTheme.typography.titleSmall)
    if (chart.points.isEmpty()) {
        Text(
            stringResource(R.string.services_chart_balance_empty),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    } else {
        BalanceLineChart(content = chart)
    }
}

private fun galleryDay(day: Int): Long {
    val cal = Calendar.getInstance()
    cal.clear()
    cal.set(2026, Calendar.AUGUST, day)
    return cal.timeInMillis
}

private fun spendSamples(): List<HistoryChartState.Spend> {
    val buckets = (1..16).map { galleryDay(it) }
    val start = buckets.first()
    val end = buckets.last()
    fun spend(points: List<ChartPoint>) = HistoryChartState.Spend(
        points = points,
        startMillis = start,
        endMillis = end,
        monthly = false,
        isIntervalSpend = false,
        buckets = buckets,
        axisMarks = listOf(0.0, 1.0, 2.0),
    )
    return listOf(
        spend(emptyList()),
        spend(listOf(ChartPoint(galleryDay(1), 2.2))),
        spend(
            (1..16).mapNotNull { day ->
                if (day == 4 || day == 5) null
                else ChartPoint(galleryDay(day), if (day < 9) 0.5 else 2.2)
            },
        ),
    )
}

private fun balanceSamples(): List<HistoryChartState.Balance> {
    val buckets = (1..16).map { galleryDay(it) }
    val start = buckets.first()
    val mid = galleryDay(9)
    val end = buckets.last()
    fun balance(points: List<ChartPoint>, inferred: Set<Long>) = HistoryChartState.Balance(
        points = points,
        startMillis = start,
        endMillis = end,
        monthly = false,
        inferredStarts = inferred,
        buckets = buckets,
        axisMarks = listOf(0.0, 30.0, 60.0),
    )
    return listOf(
        balance(emptyList(), emptySet()),
        balance(listOf(ChartPoint(end, 42.0)), emptySet()),
        balance(
            listOf(
                ChartPoint(start, 49.62),
                ChartPoint(mid, 58.33),
                ChartPoint(end, 42.0),
            ),
            setOf(start, mid),
        ),
    )
}
