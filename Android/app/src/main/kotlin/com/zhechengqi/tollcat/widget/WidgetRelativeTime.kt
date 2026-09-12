package com.zhechengqi.tollcat.widget

import android.content.Context
import android.text.format.DateUtils
import com.zhechengqi.tollcat.R

/**
 * 中号 / 大号底部那句「上次刷新 …」。档位和详情页历史同一套：
 * 刚刚 / 24 小时内相对时间 / 月日。不走 JNI——小组件进程不许加载 MeterCore。
 */
object WidgetRelativeTime {
    fun lastRefreshCaption(context: Context, fetchedAtMillis: Long, nowMillis: Long): String {
        return context.getString(R.string.services_last_refresh, relative(context, fetchedAtMillis, nowMillis))
    }

    fun relative(context: Context, fetchedAtMillis: Long, nowMillis: Long): String {
        val elapsed = nowMillis - fetchedAtMillis
        if (elapsed < 60_000L) {
            return context.getString(R.string.relative_just_now)
        }
        if (elapsed < 86_400_000L) {
            return DateUtils.getRelativeTimeSpanString(
                fetchedAtMillis,
                nowMillis,
                DateUtils.MINUTE_IN_MILLIS,
            ).toString()
        }
        return DateUtils.formatDateTime(
            context,
            fetchedAtMillis,
            DateUtils.FORMAT_SHOW_DATE or DateUtils.FORMAT_NO_YEAR,
        )
    }
}
