package com.zhechengqi.tollcat.ui

enum class AppearanceMode {
    System,
    Light,
    Dark,
    ;

    val storageValue: String
        get() = when (this) {
            System -> "system"
            Light -> "light"
            Dark -> "dark"
        }

    fun resolvesDark(systemDark: Boolean): Boolean = when (this) {
        System -> systemDark
        Light -> false
        Dark -> true
    }

    companion object {
        fun fromStorage(raw: String?): AppearanceMode = when (raw) {
            "light" -> Light
            "dark" -> Dark
            "system" -> System
            else -> Dark
        }
    }
}
