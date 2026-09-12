package com.zhechengqi.tollcat.settings

import android.content.Context
import com.zhechengqi.tollcat.R
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/**
 * 通知文案。和 iOS `ReminderNotificationCopy` 同一组句子。
 *
 * 不出现金额、百分比、provider 名单（SPEC 12.5）。触发时 App 没运行，
 * 能拿到的只有上次刷新时刻；只说「去看看」，可以带「上次刷新 N 天前」。
 */
object ReminderNotificationCopy {
    fun title(context: Context): String {
        return context.getString(R.string.settings_reminder_notice_title)
    }

    fun lookBody(context: Context): String {
        return context.getString(R.string.settings_reminder_notice_body)
    }

    fun body(
        context: Context,
        lastRefreshAtMillis: Long?,
        nowMillis: Long,
        zoneId: ZoneId = ZoneId.systemDefault(),
    ): String {
        val look = lookBody(context)
        if (lastRefreshAtMillis == null) return look
        val days = daysBetween(lastRefreshAtMillis, nowMillis, zoneId)
        val extra = when {
            days <= 0 -> context.getString(R.string.settings_reminder_notice_today)
            days == 1 -> context.getString(R.string.settings_reminder_notice_yesterday)
            else -> context.getString(R.string.settings_reminder_notice_days, days)
        }
        return look + extra
    }

    internal fun daysBetween(
        fromMillis: Long,
        toMillis: Long,
        zoneId: ZoneId = ZoneId.systemDefault(),
    ): Int {
        val from = Instant.ofEpochMilli(fromMillis).atZone(zoneId).toLocalDate()
        val to = Instant.ofEpochMilli(toMillis).atZone(zoneId).toLocalDate()
        return ChronoUnit.DAYS.between(from, to).toInt()
    }
}
