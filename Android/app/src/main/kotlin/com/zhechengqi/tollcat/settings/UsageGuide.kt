package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.R

data class UsageGuide(
    val id: String,
    val title: Int,
    val body: Int,
)

object UsageGuides {
    val money = listOf(
        UsageGuide("kind_usage", R.string.settings_money_usage_title, R.string.settings_money_usage_body),
        UsageGuide("kind_prepaid", R.string.settings_money_prepaid_title, R.string.settings_money_prepaid_body),
        UsageGuide("kind_subscription", R.string.settings_money_subscription_title, R.string.settings_money_subscription_body),
        UsageGuide("kind_freetier", R.string.settings_money_freetier_title, R.string.settings_money_freetier_body),
    )

    val product = listOf(
        UsageGuide(
            "heroExcludesSubscriptions",
            R.string.settings_guide_hero_title,
            R.string.settings_guide_hero_body,
        ),
        UsageGuide(
            "awsRefreshCostsMoney",
            R.string.settings_guide_aws_title,
            R.string.settings_guide_aws_body,
        ),
        UsageGuide(
            "keysStayOnThisDevice",
            R.string.settings_guide_keys_title,
            R.string.settings_guide_keys_body,
        ),
        UsageGuide(
            "inboxForMissingAPIs",
            R.string.settings_guide_inbox_title,
            R.string.settings_guide_inbox_body,
        ),
        UsageGuide(
            "widgetOnLockScreen",
            R.string.settings_guide_widget_title,
            R.string.settings_guide_widget_body,
        ),
    )

    val all: List<UsageGuide> = money + product

    fun find(id: String): UsageGuide? = all.firstOrNull { it.id == id }
}
