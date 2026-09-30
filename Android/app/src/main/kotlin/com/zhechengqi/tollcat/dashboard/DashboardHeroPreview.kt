package com.zhechengqi.tollcat.dashboard

/** 预览与画廊用的顶栏状态：设计稿那组数字（8 月 16 日，$47.20 → $87.70）。 */
internal object DashboardHeroPreview {
    val state = DashboardHeroState(
        periodTitle = "8 月",
        amount = "$47.20",
        projected = "$87.70",
        monthProgress = MonthProgress(
            fraction = 16f / 31f,
            startLabel = "8月1日",
            todayLabel = "8月16日",
            endLabel = "8月31日",
        ),
        subscriptionNote = "本月订阅 $24.00 · 已计入",
        includesSubscriptions = true,
        showsScopeToggle = true,
        staleCaption = null,
        filterNote = null,
    )
}
