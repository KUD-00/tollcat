package com.zhechengqi.tollcat.dashboard

import androidx.annotation.StringRes
import com.zhechengqi.tollcat.DashboardSnapshot
import com.zhechengqi.tollcat.R

enum class DashboardCatMood(val raw: String, @StringRes val labelRes: Int) {
    Normal("normal", R.string.dashboard_cat_mood_normal),
    Sleeping("sleeping", R.string.dashboard_cat_mood_sleeping),
    Saved("saved", R.string.dashboard_cat_mood_saved),
    Alert("alert", R.string.dashboard_cat_mood_alert),
    Shocked("shocked", R.string.dashboard_cat_mood_shocked),
    Awkward("awkward", R.string.dashboard_cat_mood_awkward),
    Dead("dead", R.string.dashboard_cat_mood_dead),
    ;

    companion object {
        /**
         * 表情由共享层的 `CatMoodResolver` 算好随仪表 JSON 过来，这里只对 raw 值。
         * 不在本地重算阈值——两套阈值迟早给出两种表情。
         */
        fun from(dashboard: DashboardSnapshot): DashboardCatMood {
            entries.firstOrNull { it.raw.equals(dashboard.catMood, ignoreCase = true) }?.let { return it }
            return if (dashboard.empty) Sleeping else Normal
        }
    }
}
