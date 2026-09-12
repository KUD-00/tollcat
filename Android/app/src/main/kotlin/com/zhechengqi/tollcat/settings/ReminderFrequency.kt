package com.zhechengqi.tollcat.settings

object ReminderFrequency {
    const val DAILY = "daily"
    const val WEEKLY = "weekly"
    const val BIWEEKLY = "biweekly"
    const val MONTHLY = "monthly"

    val all = listOf(DAILY, WEEKLY, BIWEEKLY, MONTHLY)

    fun normalize(raw: String?): String {
        return all.firstOrNull { it == raw } ?: WEEKLY
    }
}
