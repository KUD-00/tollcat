package com.zhechengqi.tollcat.developer

import com.zhechengqi.tollcat.R
import com.zhechengqi.tollcat.dashboard.DashboardModules

/** 实验室目录的分组。跟编辑面同一份模块清单，不另开名单。 */
enum class DashboardLabSection {
    Hero,
    Attention,
    Optional,
    ;

    val titleRes: Int
        get() = when (this) {
            Hero -> R.string.dev_lab_section_hero
            Attention -> R.string.dashboard_attention
            Optional -> R.string.dev_lab_section_optional
        }

    val ids: List<String>
        get() = DashboardLabModules.defaultOrder.filter { section(it) == this }

    companion object {
        fun section(id: String): DashboardLabSection = when {
            id == DashboardLabModules.MONTH_TO_DATE || id in DashboardModules.fixedSlot -> Hero
            id in DashboardModules.attention -> Attention
            else -> Optional
        }
    }
}
