package com.zhechengqi.tollcat.settings

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.PreferencesStore
import com.zhechengqi.tollcat.R
import java.text.DateFormat
import java.text.DateFormatSymbols
import java.util.Calendar

/** 设置首页那一行用的频率 + 时刻摘要。进子页才改。 */
@Composable
fun reminderScheduleSummary(preferences: PreferencesStore): String {
    val frequency = reminderFrequencyTitle(ReminderFrequency.normalize(preferences.reminderFrequency))
    val time = formatReminderTime(preferences.reminderHour, preferences.reminderMinute)
    return when (ReminderFrequency.normalize(preferences.reminderFrequency)) {
        ReminderFrequency.WEEKLY, ReminderFrequency.BIWEEKLY ->
            "$frequency · ${reminderWeekdayTitle(preferences.reminderWeekday)} · $time"
        ReminderFrequency.MONTHLY ->
            "$frequency · ${stringResource(R.string.settings_reminder_day_value, preferences.reminderDayOfMonth)} · $time"
        else -> "$frequency · $time"
    }
}

@Composable
fun reminderFrequencyTitle(value: String): String {
    return when (value) {
        ReminderFrequency.DAILY -> stringResource(R.string.settings_reminder_daily)
        ReminderFrequency.WEEKLY -> stringResource(R.string.settings_reminder_weekly)
        ReminderFrequency.BIWEEKLY -> stringResource(R.string.settings_reminder_biweekly)
        else -> stringResource(R.string.settings_reminder_monthly)
    }
}

fun reminderWeekdayChoices(): List<Int> {
    val first = Calendar.getInstance().firstDayOfWeek
    return (0 until 7).map { ((first - 1 + it) % 7) + 1 }
}

@Composable
fun reminderWeekdayTitle(weekday: Int): String {
    val symbols = DateFormatSymbols.getInstance(LocalContext.current.resources.configuration.locales[0])
    val names = symbols.weekdays
    return if (weekday in names.indices) names[weekday] else weekday.toString()
}

fun formatReminderTime(hour: Int, minute: Int): String {
    val calendar = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, hour)
        set(Calendar.MINUTE, minute)
        set(Calendar.SECOND, 0)
    }
    return DateFormat.getTimeInstance(DateFormat.SHORT).format(calendar.time)
}
