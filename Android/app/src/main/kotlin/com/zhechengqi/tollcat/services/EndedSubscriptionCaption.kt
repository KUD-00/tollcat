package com.zhechengqi.tollcat.services

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.SubscriptionRow
import java.text.SimpleDateFormat
import java.util.Calendar

/**
 * 「已结束 · 2026年8月」；结束月还没到就写「到 2026年11月 为止」。没有终点就是 null。
 *
 * 服务页和详情页都要写这一句，收在一处——两边各拼一遍迟早会有一边忘了加月份。
 */
@Composable
fun endedMonthCaption(row: SubscriptionRow, hasEnded: Boolean): String? {
    val year = row.endYear ?: return null
    val monthIndex = row.endMonth ?: return null
    val locale = LocalContext.current.resources.configuration.locales[0]
    val calendar = Calendar.getInstance().apply {
        clear()
        set(year, monthIndex - 1, 1)
    }
    // 年月的次序跟系统语言走，别写死「%d年%d月」——英文界面上那样会读成中文格式。
    val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, "yMMMM")
    val month = SimpleDateFormat(pattern, locale).format(calendar.time)
    // 结束月填在未来的那种还在付，写「到 X 为止」，不能写成「已结束」。
    return if (hasEnded) {
        stringResource(R.string.services_ended_month, month)
    } else {
        stringResource(R.string.services_through_month, month)
    }
}

/** 订阅行的副标题：还在付写周期，退掉了写「月付 · ×3 · 已结束 · 2026年8月」。 */
@Composable
fun subscriptionCaption(row: SubscriptionRow, hasEnded: Boolean): String {
    val period = stringResource(
        if (row.period == "annual") {
            R.string.services_subscription_annual
        } else {
            R.string.services_subscription_monthly
        },
    )
    val withQuantity = if (row.quantity > 1) {
        stringResource(R.string.services_subscription_qty, period, row.quantity)
    } else {
        period
    }
    val ended = endedMonthCaption(row, hasEnded) ?: return withQuantity
    return stringResource(R.string.services_dot_join, withQuantity, ended)
}
