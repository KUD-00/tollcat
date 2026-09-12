package com.zhechengqi.tollcat.settings

object AppearancePreference {
    const val SYSTEM = "system"
    const val LIGHT = "light"
    const val DARK = "dark"

    val all = listOf(LIGHT, DARK, SYSTEM)

    fun normalize(raw: String?): String {
        return all.firstOrNull { it == raw } ?: SYSTEM
    }
}
