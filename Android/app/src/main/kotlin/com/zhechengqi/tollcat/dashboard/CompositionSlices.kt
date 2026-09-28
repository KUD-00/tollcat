package com.zhechengqi.tollcat.dashboard

import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.MoneyDisplay

/** 超过 [CompositionTones.namedLimit] 家时，尾巴合成一段「其他」。 */
fun compositionSlices(
    rows: List<CompositionRow>,
    otherLabel: String,
    namedLimit: Int = CompositionTones.namedLimit,
): List<CompositionRow> {
    if (rows.size <= namedLimit) return rows
    val named = rows.take(namedLimit)
    val rest = rows.drop(namedLimit)
    val other = CompositionRow(
        providerId = "other",
        displayName = otherLabel,
        colorKey = "other",
        amount = summedAmount(rest),
        percent = rest.sumOf { it.percent }.coerceAtMost(100),
        fraction = rest.sumOf { it.fraction.toDouble() }.toFloat(),
    )
    return named + other
}

private fun summedAmount(rows: List<CompositionRow>): String {
    if (rows.isEmpty()) return ""
    if (rows.size == 1) return rows[0].amount
    val numbers = rows.map { row ->
        val compact = row.amount.replace(",", "").replace(" ", "")
        Regex("""-?\d+(?:\.\d+)?""").find(compact)?.value?.toDoubleOrNull()
    }
    if (numbers.any { it == null }) return ""
    val sum = numbers.filterNotNull().sum()
    return MoneyDisplay.formatUsd("%.2f".format(sum))
}
