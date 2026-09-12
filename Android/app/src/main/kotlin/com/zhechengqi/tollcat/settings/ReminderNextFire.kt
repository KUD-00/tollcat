package com.zhechengqi.tollcat.settings

import java.util.Calendar
import java.util.TimeZone

/**
 * 下一次应响铃的时刻。日历算术与 iOS `ReminderScheduler.nextDate` 同一套：
 * 星期用 Calendar 的 1=周日…7=周六；每月 31 号钳到月末。
 *
 * 时间从参数进来，不读 `System.currentTimeMillis()`。
 */
object ReminderNextFire {
    fun nextMillis(
        frequency: String,
        hour: Int,
        minute: Int,
        weekday: Int,
        dayOfMonth: Int,
        nowMillis: Long,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long? {
        val safeHour = hour.coerceIn(0, 23)
        val safeMinute = minute.coerceIn(0, 59)
        val safeWeekday = weekday.coerceIn(Calendar.SUNDAY, Calendar.SATURDAY)
        val safeDay = dayOfMonth.coerceIn(1, 31)
        return when (ReminderFrequency.normalize(frequency)) {
            ReminderFrequency.DAILY -> nextDaily(safeHour, safeMinute, nowMillis, timeZone)
            ReminderFrequency.WEEKLY -> nextWeekday(
                hour = safeHour,
                minute = safeMinute,
                weekday = safeWeekday,
                intervalDays = 7,
                nowMillis = nowMillis,
                timeZone = timeZone,
            )
            ReminderFrequency.BIWEEKLY -> nextWeekday(
                hour = safeHour,
                minute = safeMinute,
                weekday = safeWeekday,
                intervalDays = 14,
                nowMillis = nowMillis,
                timeZone = timeZone,
            )
            else -> nextMonthly(safeHour, safeMinute, safeDay, nowMillis, timeZone)
        }
    }

    private fun nextDaily(
        hour: Int,
        minute: Int,
        nowMillis: Long,
        timeZone: TimeZone,
    ): Long {
        val calendar = calendarAt(nowMillis, timeZone)
        stampTime(calendar, hour, minute)
        if (calendar.timeInMillis >= nowMillis) return calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        return calendar.timeInMillis
    }

    private fun nextWeekday(
        hour: Int,
        minute: Int,
        weekday: Int,
        intervalDays: Int,
        nowMillis: Long,
        timeZone: TimeZone,
    ): Long {
        val calendar = calendarAt(nowMillis, timeZone)
        val todayWeekday = calendar.get(Calendar.DAY_OF_WEEK)
        var daysAhead = weekday - todayWeekday
        if (daysAhead < 0) daysAhead += 7
        startOfDay(calendar)
        calendar.add(Calendar.DAY_OF_MONTH, daysAhead)
        stampTime(calendar, hour, minute)
        if (calendar.timeInMillis >= nowMillis) return calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, intervalDays)
        return calendar.timeInMillis
    }

    private fun nextMonthly(
        hour: Int,
        minute: Int,
        dayOfMonth: Int,
        nowMillis: Long,
        timeZone: TimeZone,
    ): Long {
        val thisMonth = calendarAt(nowMillis, timeZone)
        thisMonth.set(Calendar.DAY_OF_MONTH, 1)
        val candidate = atDayOfMonth(thisMonth, dayOfMonth, hour, minute)
        if (candidate >= nowMillis) return candidate
        thisMonth.add(Calendar.MONTH, 1)
        return atDayOfMonth(thisMonth, dayOfMonth, hour, minute)
    }

    private fun atDayOfMonth(
        monthStart: Calendar,
        dayOfMonth: Int,
        hour: Int,
        minute: Int,
    ): Long {
        val calendar = monthStart.clone() as Calendar
        val days = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth.coerceIn(1, days))
        stampTime(calendar, hour, minute)
        return calendar.timeInMillis
    }

    private fun calendarAt(nowMillis: Long, timeZone: TimeZone): Calendar {
        val calendar = Calendar.getInstance(timeZone)
        calendar.timeInMillis = nowMillis
        return calendar
    }

    private fun startOfDay(calendar: Calendar) {
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
    }

    private fun stampTime(calendar: Calendar, hour: Int, minute: Int) {
        calendar.set(Calendar.HOUR_OF_DAY, hour)
        calendar.set(Calendar.MINUTE, minute)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
    }
}
