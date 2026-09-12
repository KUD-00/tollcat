package com.zhechengqi.tollcat.dashboard

import android.content.res.Configuration
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatTheme
import com.zhechengqi.tollcat.ui.MeterSpacing
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * 筛选抽屉里折叠的自定义区间。起讫都是月，不是日。
 *
 * 落成 `periodKind=months, monthsBack=newest, monthCount=span`。
 */
@Composable
fun DashboardFilterCustomRow(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    oldestBack: Int,
    newestBack: Int,
    nowMillis: Long,
    isCustomRange: Boolean,
    onRangeChange: (oldestBack: Int, newestBack: Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val monthCount = (oldestBack - newestBack + 1).coerceAtLeast(1)
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(MeterSpacing.xs),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = MeterSpacing.minTap)
                .clickable { onExpandedChange(!expanded) },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
        ) {
            Text(
                text = stringResource(R.string.dashboard_filter_custom),
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f),
            )
            if (isCustomRange) {
                Text(
                    text = stringResource(R.string.dashboard_filter_custom_count, monthCount),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary,
                )
            }
        }
        AnimatedVisibility(visible = expanded) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(MeterSpacing.sm),
            ) {
                MonthSelectChip(
                    monthsBack = oldestBack,
                    nowMillis = nowMillis,
                    onSelect = { onRangeChange(it, newestBack) },
                    modifier = Modifier.weight(1f),
                )
                MonthSelectChip(
                    monthsBack = newestBack,
                    nowMillis = nowMillis,
                    onSelect = { onRangeChange(oldestBack, it) },
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun MonthSelectChip(
    monthsBack: Int,
    nowMillis: Long,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    var expanded by remember { mutableStateOf(false) }
    Box(modifier) {
        FilterChip(
            selected = true,
            onClick = { expanded = true },
            label = { Text(formatDashboardMonth(monthsBack, nowMillis)) },
        )
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
        ) {
            for (back in 0..DashboardFilterState.MAX_MONTHS_BACK) {
                DropdownMenuItem(
                    text = { Text(formatDashboardMonth(back, nowMillis)) },
                    onClick = {
                        expanded = false
                        onSelect(back)
                    },
                )
            }
        }
    }
}

/** 日历月名。自定义选择器要写出是哪一个月，不写「本月」。 */
internal fun formatDashboardMonth(
    monthsBack: Int,
    nowMillis: Long,
    locale: Locale = Locale.getDefault(),
): String {
    val zone = ZoneId.systemDefault()
    val now = YearMonth.from(Instant.ofEpochMilli(nowMillis).atZone(zone))
    val month = now.minusMonths(monthsBack.toLong())
    val pattern = if (month.year == now.year) "LLLL" else "LLLL uuuu"
    return DateTimeFormatter.ofPattern(pattern, locale).format(month)
}

@Preview(name = "Light", showBackground = true)
@Preview(name = "Dark", showBackground = true, uiMode = Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DashboardFilterCustomRowPreview() {
    TollCatTheme {
        DashboardFilterCustomRow(
            expanded = true,
            onExpandedChange = {},
            oldestBack = 4,
            newestBack = 2,
            nowMillis = System.currentTimeMillis(),
            isCustomRange = true,
            onRangeChange = { _, _ -> },
        )
    }
}
