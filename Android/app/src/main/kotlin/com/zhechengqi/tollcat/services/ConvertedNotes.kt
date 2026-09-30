package com.zhechengqi.tollcat.services

import com.zhechengqi.tollcat.CompositionRow
import com.zhechengqi.tollcat.MoneyDisplay
import com.zhechengqi.tollcat.SnapshotRow
import com.zhechengqi.tollcat.SubscriptionModuleItem
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/** 快照上的换算注记。多钱包和单槽汇率都是这一份形状。 */
data class ConvertedNote(
    val currency: String,
    val amount: String,
    val usdPerUnit: String,
    val usd: String,
) {
    val isConverted: Boolean get() = !currency.equals("USD", ignoreCase = true)

    fun walletLine(): String = "$currency $amount"
}

fun parseConverted(json: String?): ConvertedNote? {
    json ?: return null
    return runCatching {
        note(JSONObject(json))
    }.getOrNull()
}

fun parseWallets(json: String?): List<ConvertedNote> {
    json ?: return emptyList()
    return runCatching {
        val array = JSONArray(json)
        (0 until array.length()).mapNotNull { index ->
            note(array.optJSONObject(index) ?: return@mapNotNull null)
        }
    }.getOrDefault(emptyList())
}

private fun note(json: JSONObject): ConvertedNote? {
    val currency = json.optString("currency").trim()
    if (currency.isEmpty()) return null
    return ConvertedNote(
        currency = currency,
        amount = json.optString("amount"),
        usdPerUnit = json.optString("usdPerUnit"),
        usd = json.optString("usd"),
    )
}

/**
 * 「（1 CNY = $0.1404）」——原币就是显示货币时不出。
 * 美元显示用原串保住位数；别的币走 formatUsd，把「1 原币折多少美元」再折成显示币。
 */
fun rateCaption(note: ConvertedNote, locale: Locale): String? {
    if (!note.isConverted) return null
    if (note.currency.equals(MoneyDisplay.currency, ignoreCase = true)) return null
    val amount = parseAmount(note.amount) ?: 0.0
    val usd = parseAmount(note.usd) ?: 0.0
    if (amount == 0.0 && usd == 0.0) return null
    val rate = if (MoneyDisplay.currency.equals("USD", ignoreCase = true)) {
        "$${note.usdPerUnit}"
    } else {
        MoneyDisplay.formatUsd(note.usdPerUnit)
    }
    return wrapped("1 ${note.currency} = $rate", locale)
}

fun conversionRateCaptions(
    convertedJson: String?,
    walletsJson: String?,
    locale: Locale,
): List<String> {
    val wallets = parseWallets(walletsJson)
    val notes = if (wallets.size >= 2) {
        wallets.filter { it.isConverted }
            .distinctBy { it.currency }
    } else {
        listOfNotNull(parseConverted(convertedJson)?.takeIf { it.isConverted })
    }
    return notes.mapNotNull { rateCaption(it, locale) }
}

fun walletBreakdown(walletsJson: String?): List<ConvertedNote> {
    val wallets = parseWallets(walletsJson)
    return if (wallets.size >= 2) wallets else emptyList()
}

private fun wrapped(body: String, locale: Locale): String {
    val fullwidth = locale.language == "zh" || locale.language == "ja"
    return if (fullwidth) "（$body）" else "($body)"
}
