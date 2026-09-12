package com.zhechengqi.tollcat.services

import android.content.Context
import android.text.format.DateUtils
import com.zhechengqi.tollcat.MeterCoreNative
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.R
import java.text.DateFormat
import java.util.Date
import java.util.Locale

/**
 * 列表行、详情「上次刷新」、读数明细同一套档位：刚刚 / 24 小时内相对时间 / 月日。
 * 口径对齐 iOS `ServiceRelativeTime`。
 */
object ServiceRelativeTime {
    fun caption(context: Context, fromMillis: Long, nowMillis: Long): String {
        val elapsed = nowMillis - fromMillis
        if (elapsed < 60_000L) {
            return context.getString(R.string.services_just_now)
        }
        if (elapsed < 86_400_000L) {
            return DateUtils.getRelativeTimeSpanString(
                fromMillis,
                nowMillis,
                DateUtils.MINUTE_IN_MILLIS,
            ).toString()
        }
        if (MeterCoreNative.loaded) {
            return MeterCoreNative.formatMonthAndDay(fromMillis, MoneyDisplay.localeTag())
        }
        return DateFormat.getDateInstance(DateFormat.MEDIUM).format(Date(fromMillis))
    }

    fun yearMonth(millis: Long, locale: Locale): String {
        return android.icu.text.DateFormat.getInstanceForSkeleton("yMMMM", locale)
            .format(Date(millis))
    }
}
