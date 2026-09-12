package com.zhechengqi.tollcat.developer

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.TollCatSession
import com.zhechengqi.tollcat.settings.SettingsNavRow
import com.zhechengqi.tollcat.settings.SettingsScaffold
import com.zhechengqi.tollcat.settings.SettingsSection
import java.text.DateFormat
import java.util.Date
import java.util.TimeZone

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DeveloperClockDestination(
    session: TollCatSession,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var picking by remember { mutableStateOf(false) }
    val current = session.nowMillis()
    val caption = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT)
        .format(Date(current))
    SettingsScaffold(
        title = stringResource(R.string.dev_clock),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsSection(title = stringResource(R.string.dev_clock_now)) {
                SettingsNavRow(
                    title = caption,
                    subtitle = stringResource(R.string.dev_clock_hint),
                    showChevron = false,
                    onClick = { picking = true },
                )
                if (session.clockOverrideMillis != null) {
                    SettingsNavRow(
                        title = stringResource(R.string.dev_clock_reset),
                        showChevron = false,
                        onClick = { session.applyClockOverride(null) },
                    )
                }
            }
            SettingsSection(title = stringResource(R.string.dev_clock_bounds)) {
                DeveloperClockPreset.entries.forEach { preset ->
                    SettingsNavRow(
                        title = stringResource(presetTitle(preset)),
                        showChevron = false,
                        onClick = {
                            session.applyClockOverride(preset.dateMillis(session.nowMillis()))
                        },
                    )
                }
            }
            Text(
                text = stringResource(R.string.dev_clock_footer),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 12.dp),
            )
            Spacer(Modifier.height(24.dp))
        }
    }
    if (picking) {
        val state = rememberDatePickerState(initialSelectedDateMillis = current)
        DatePickerDialog(
            onDismissRequest = { picking = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        state.selectedDateMillis?.let { utcDay ->
                            val local = utcDay + TimeZone.getDefault().getOffset(utcDay)
                            session.applyClockOverride(local)
                        }
                        picking = false
                    },
                ) {
                    Text(stringResource(R.string.dev_clock_apply))
                }
            },
            dismissButton = {
                TextButton(onClick = { picking = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
        ) {
            DatePicker(state = state)
        }
    }
}

private fun presetTitle(preset: DeveloperClockPreset): Int {
    return when (preset) {
        DeveloperClockPreset.MonthStart -> R.string.dev_clock_month_start
        DeveloperClockPreset.MonthEnd -> R.string.dev_clock_month_end
        DeveloperClockPreset.Feb29 -> R.string.dev_clock_feb29
        DeveloperClockPreset.NewYear -> R.string.dev_clock_new_year
    }
}
