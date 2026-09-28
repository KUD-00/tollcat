package com.zhechengqi.tollcat.dashboard

import android.text.format.DateFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * 顶栏进度条：这个月走到第几天了。只在当月（有「预计月底」时）出现，
 * 回看过去的月份没有「今天」。三个刻度按 locale 的「月 日」骨架格式化。
 */
data class MonthProgress(
    val fraction: Float,
    val startLabel: String,
    val todayLabel: String,
    val endLabel: String,
) {
    companion object {
        fun at(nowMillis: Long, locale: Locale): MonthProgress {
            val calendar = Calendar.getInstance(locale).apply { timeInMillis = nowMillis }
            val day = calendar.get(Calendar.DAY_OF_MONTH)
            val days = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
            val format = SimpleDateFormat(DateFormat.getBestDateTimePattern(locale, "MMMd"), locale)
            val today = format.format(calendar.time)
            calendar.set(Calendar.DAY_OF_MONTH, 1)
            val start = format.format(calendar.time)
            calendar.set(Calendar.DAY_OF_MONTH, days)
            val end = format.format(calendar.time)
            return MonthProgress(
                fraction = (day.toFloat() / days).coerceIn(0f, 1f),
                startLabel = start,
                todayLabel = today,
                endLabel = end,
            )
        }
    }
}
