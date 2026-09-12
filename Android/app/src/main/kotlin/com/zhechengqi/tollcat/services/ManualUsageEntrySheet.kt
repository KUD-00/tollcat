package com.zhechengqi.tollcat.services

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.ui.PrimaryButton
import com.zhechengqi.tollcat.ui.TollCatSheet
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ManualUsageEntrySheet(
    updating: Boolean,
    snapshots: List<SnapshotRow>,
    onDismiss: () -> Unit,
    onSave: (amount: String, periodMillis: Long) -> Unit,
) {
    val now = remember { System.currentTimeMillis() }
    val maxPeriod = remember(now) { startOfMonthMillis(now) }
    val minPeriod = remember(maxPeriod) { addMonths(maxPeriod, -11) }
    var periodMillis by remember { mutableLongStateOf(maxPeriod) }
    var amount by remember { mutableStateOf(amountForMonth(snapshots, maxPeriod)) }
    var pickingMonth by remember { mutableStateOf(false) }
    val parsed = parseAmount(amount)
    val locale = LocalConfiguration.current.locales[0]
    val isCurrent = startOfMonthMillis(now) == startOfMonthMillis(periodMillis)
    val minYear = yearOf(minPeriod)
    val maxYear = yearOf(maxPeriod)

    TollCatSheet(onDismiss = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 24.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                text = stringResource(
                    if (updating) R.string.services_update_usage else R.string.services_fill_usage,
                ),
                style = MaterialTheme.typography.headlineSmall,
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.services_usage_period),
                    style = MaterialTheme.typography.bodyLarge,
                )
                OutlinedButton(onClick = { pickingMonth = true }) {
                    Text(yearMonthLabel(periodMillis, locale))
                }
            }
            TextField(
                value = amount,
                onValueChange = { amount = it },
                modifier = Modifier.fillMaxWidth(),
                label = {
                    Text(
                        if (isCurrent) {
                            stringResource(R.string.services_usage_month)
                        } else {
                            yearMonthLabel(periodMillis, locale)
                        },
                    )
                },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                prefix = { Text("$") },
                supportingText = {
                    Text(
                        stringResource(
                            if (isCurrent) {
                                R.string.services_usage_footer
                            } else {
                                R.string.services_usage_footer_past
                            },
                        ),
                    )
                },
            )
            PrimaryButton(
                onClick = {
                    parsed?.let { onSave("%.2f".format(it), periodMillis) }
                },
                enabled = parsed != null && parsed >= 0,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.services_save))
            }
            Spacer(Modifier.height(12.dp))
        }
    }

    if (pickingMonth) {
        YearMonthPickerDialog(
            title = stringResource(R.string.services_usage_period),
            initialMillis = periodMillis,
            yearMin = minYear,
            yearMax = maxYear,
            onConfirm = { millis ->
                val clamped = millis.coerceIn(minPeriod, maxPeriod)
                val month = startOfMonthMillis(clamped)
                periodMillis = month
                amount = amountForMonth(snapshots, month)
                pickingMonth = false
            },
            onDismiss = { pickingMonth = false },
        )
    }
}

private fun amountForMonth(snapshots: List<SnapshotRow>, monthStart: Long): String {
    val start = startOfMonthMillis(monthStart)
    return snapshots
        .filter { it.source == "manual" && startOfMonthMillis(it.periodStartMillis) == start }
        .maxByOrNull { it.fetchedAtMillis }
        ?.currentSpendUsd
        .orEmpty()
}

private fun yearMonthLabel(millis: Long, locale: Locale): String {
    return android.icu.text.DateFormat.getInstanceForSkeleton("yMMMM", locale).format(Date(millis))
}

private fun startOfMonthMillis(millis: Long): Long {
    return Calendar.getInstance().apply {
        timeInMillis = millis
        set(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}

private fun addMonths(millis: Long, months: Int): Long {
    return Calendar.getInstance().apply {
        timeInMillis = millis
        add(Calendar.MONTH, months)
    }.timeInMillis
}

private fun yearOf(millis: Long): Int {
    return Calendar.getInstance().apply { timeInMillis = millis }.get(Calendar.YEAR)
}
