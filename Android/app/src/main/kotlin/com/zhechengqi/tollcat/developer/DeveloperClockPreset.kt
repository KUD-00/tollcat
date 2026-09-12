package com.zhechengqi.tollcat.developer

import java.util.Calendar

enum class DeveloperClockPreset {
    MonthStart,
    MonthEnd,
    Feb29,
    NewYear,
    ;

    fun dateMillis(nowMillis: Long): Long {
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = nowMillis
        when (this) {
            MonthStart -> {
                calendar.set(Calendar.DAY_OF_MONTH, 1)
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
            }
            MonthEnd -> {
                calendar.set(Calendar.DAY_OF_MONTH, 1)
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                calendar.add(Calendar.MONTH, 1)
                calendar.add(Calendar.MILLISECOND, -1)
            }
            Feb29 -> {
                val year = calendar.get(Calendar.YEAR)
                var found = false
                for (offset in 0 until 8) {
                    calendar.clear()
                    calendar.set(Calendar.YEAR, year + offset)
                    calendar.set(Calendar.MONTH, Calendar.FEBRUARY)
                    calendar.set(Calendar.DAY_OF_MONTH, 29)
                    calendar.set(Calendar.HOUR_OF_DAY, 12)
                    if (calendar.get(Calendar.MONTH) == Calendar.FEBRUARY &&
                        calendar.get(Calendar.DAY_OF_MONTH) == 29
                    ) {
                        found = true
                        break
                    }
                }
                if (!found) {
                    calendar.clear()
                    calendar.set(2028, Calendar.FEBRUARY, 29, 12, 0, 0)
                }
            }
            NewYear -> {
                calendar.add(Calendar.YEAR, 1)
                calendar.set(Calendar.MONTH, Calendar.JANUARY)
                calendar.set(Calendar.DAY_OF_MONTH, 1)
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
            }
        }
        return calendar.timeInMillis
    }
}
