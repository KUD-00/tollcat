package com.zhechengqi.tollcat.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReminderDestination(
    preferences: PreferencesStore,
    controller: ReminderEnableController,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var frequency by remember { mutableStateOf(preferences.reminderFrequency) }
    var hour by remember { mutableStateOf(preferences.reminderHour) }
    var minute by remember { mutableStateOf(preferences.reminderMinute) }
    var weekday by remember { mutableStateOf(preferences.reminderWeekday) }
    var dayOfMonth by remember { mutableStateOf(preferences.reminderDayOfMonth) }
    var pickingTime by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val timeLabel = remember(hour, minute) { formatReminderTime(hour, minute) }
    val is24Hour = android.text.format.DateFormat.is24HourFormat(context)

    SettingsScaffold(
        title = stringResource(R.string.settings_reminder),
        onBack = onBack,
        modifier = modifier,
    ) { inner ->
        Column(
            modifier = Modifier
                .padding(inner)
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
        ) {
            SettingsGroup(modifier = Modifier.padding(top = 8.dp)) {
                SettingsSwitchRow(
                    title = stringResource(R.string.settings_reminder),
                    subtitle = if (controller.showsDenied) {
                        stringResource(R.string.settings_reminder_denied)
                    } else {
                        stringResource(R.string.settings_reminder_note)
                    },
                    checked = controller.enabled,
                    onCheckedChange = controller::onToggle,
                )
                if (controller.showsDenied) {
                    ReminderDeniedRow(onOpenSystemSettings = controller::openSystemNotificationSettings)
                }
            }
            if (controller.enabled) {
                SettingsSection(title = stringResource(R.string.settings_reminder_frequency)) {
                    SettingsToggleGroupRow(
                        title = null,
                        options = ReminderFrequency.all.map { value -> reminderFrequencyTitle(value) to value },
                        selected = frequency,
                        onSelect = { value ->
                            frequency = value
                            preferences.reminderFrequency = value
                            controller.reschedule()
                        },
                    )
                }
                SettingsSection(title = stringResource(R.string.settings_reminder_time)) {
                    SettingsNavRow(
                        title = stringResource(R.string.settings_reminder_time),
                        subtitle = timeLabel,
                        onClick = { pickingTime = true },
                        showChevron = false,
                    )
                }
                if (frequency == ReminderFrequency.WEEKLY || frequency == ReminderFrequency.BIWEEKLY) {
                    SettingsSection(title = stringResource(R.string.settings_reminder_weekday)) {
                        reminderWeekdayChoices().forEach { day ->
                            SettingsRadioRow(
                                title = reminderWeekdayTitle(day),
                                selected = weekday == day,
                                onClick = {
                                    weekday = day
                                    preferences.reminderWeekday = day
                                    controller.reschedule()
                                },
                            )
                        }
                    }
                }
                if (frequency == ReminderFrequency.MONTHLY) {
                    SettingsSection(title = stringResource(R.string.settings_reminder_day)) {
                        (1..31).forEach { day ->
                            SettingsRadioRow(
                                title = stringResource(R.string.settings_reminder_day_value, day),
                                selected = dayOfMonth == day,
                                onClick = {
                                    dayOfMonth = day
                                    preferences.reminderDayOfMonth = day
                                    controller.reschedule()
                                },
                            )
                        }
                    }
                }
            }
            Text(
                text = stringResource(R.string.settings_reminder_android_note),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 32.dp, vertical = 16.dp),
            )
        }
    }
    if (pickingTime) {
        val state = rememberTimePickerState(initialHour = hour, initialMinute = minute, is24Hour = is24Hour)
        AlertDialog(
            onDismissRequest = { pickingTime = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        hour = state.hour
                        minute = state.minute
                        preferences.reminderHour = state.hour
                        preferences.reminderMinute = state.minute
                        controller.reschedule()
                        pickingTime = false
                    },
                ) {
                    Text(stringResource(R.string.settings_reminder_time_set))
                }
            },
            dismissButton = {
                TextButton(onClick = { pickingTime = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
            text = { TimePicker(state = state) },
        )
    }
}
