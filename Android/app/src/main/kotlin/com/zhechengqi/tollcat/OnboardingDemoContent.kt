package com.zhechengqi.tollcat

import androidx.annotation.StringRes

/**
 * 开场预览用的设计稿数字（SPEC 第 04 节），不是运行时取数。和 iOS `OnboardingDemoContent` 同一组。
 *
 * 按新用户的默认口径摆：只算按量，大数字 43.20，GitHub 那 $4 订阅不进大数字。
 * 金额存 USD 十进制字符串，显示时按下拉里选的币种走 Swift 侧格式化，换币种当场改写。
 */
internal object OnboardingDemoContent {
    const val VARIABLE_USD = "43.20"
    const val PROJECTED_USD = "90.00"

    /** 设计稿那一天（2026-08-16）。顶栏的月进度条和「今天」要和样例数字对得上。 */
    const val CLOCK_MILLIS = 1_786_881_600_000L

    data class Service(val id: String, val name: String)

    data class AddRow(val id: String, val name: String, @param:StringRes val kindRes: Int)

    /** 第 2 页示意里「这台设备直接去问」的那三家：设计稿里花得最多的前三家。 */
    val sourcePreview = listOf(
        Service("aws", "AWS"),
        Service("cloudflare", "Cloudflare"),
        Service("openai", "OpenAI"),
    )

    val addPreview = listOf(
        AddRow("aws", "AWS", R.string.kind_usage_title),
        AddRow("cloudflare", "Cloudflare", R.string.kind_usage_title),
        AddRow("openai", "OpenAI", R.string.kind_prepaid_title),
        AddRow("github", "GitHub", R.string.kind_plan_usage_title),
    )

    /** 仪表顶栏吃的那份快照：只填顶栏读的几格，其余沿用空仪表的默认值。 */
    fun heroSnapshot(monthTitle: String, format: (String) -> String): DashboardSnapshot {
        val total = format(VARIABLE_USD)
        return DashboardSnapshot.vacant.copy(
            empty = false,
            monthTitle = monthTitle,
            allowsProjection = true,
            formattedTotal = total,
            formattedProjected = format(PROJECTED_USD),
        )
    }
}
