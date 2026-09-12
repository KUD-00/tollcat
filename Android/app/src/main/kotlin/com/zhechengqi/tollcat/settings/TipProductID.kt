package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.R

/**
 * 三档消耗型 IAP。ID 必须和 iOS `TipProductID` / Play Console 一致。
 */
enum class TipProductID(
    val raw: String,
    val titleRes: Int,
    val treat: TipTreatKind,
) {
    Small("com.zhechengqi.tollcat.tip.small", R.string.settings_tip_candy, TipTreatKind.Candy),
    Medium("com.zhechengqi.tollcat.tip.medium", R.string.settings_tip_coffee, TipTreatKind.Coffee),
    Large("com.zhechengqi.tollcat.tip.large", R.string.settings_tip_pizza, TipTreatKind.Pizza),
    ;

    companion object {
        val allRawValues: List<String> = entries.map { it.raw }

        fun fromRaw(raw: String): TipProductID? = entries.firstOrNull { it.raw == raw }
    }
}
