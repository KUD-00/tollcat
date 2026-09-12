package com.zhechengqi.tollcat.settings

/** 和 Worker / iOS 同一份上限（shared/api-contract.json）。 */
object TipFieldLimits {
    const val NAME = 40
    const val MESSAGE = 500

    fun clampName(raw: String?): String? = clamp(raw, NAME)

    fun clampMessage(raw: String?): String? = clamp(raw, MESSAGE)

    private fun clamp(raw: String?, limit: Int): String? {
        val trimmed = raw?.trim().orEmpty()
        if (trimmed.isEmpty()) return null
        return trimmed.take(limit)
    }
}
