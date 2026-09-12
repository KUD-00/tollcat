package com.zhechengqi.tollcat.settings

/** 配色来源：跟随壁纸动态取色，或 TollCat 蓝品牌静态方案。 */
object ColorSourcePreference {
    const val DYNAMIC = "dynamic"
    const val BRAND = "brand"

    val all = listOf(DYNAMIC, BRAND)

    fun normalize(raw: String?): String {
        return all.firstOrNull { it == raw } ?: DYNAMIC
    }
}
