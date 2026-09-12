package com.zhechengqi.tollcat.settings

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 本机打赏记录。上报失败也要留着，下次打开再发；所以交易凭据一起落盘。
 * 不进账本 SQLite——那是账单，这是打赏。
 */
class TipStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun all(): List<TipHistoryItem> {
        return load().sortedByDescending { it.purchasedAtMillis }
    }

    fun unsynced(): List<TipHistoryItem> {
        return load().filter { !it.isSubmitted }
    }

    fun fetch(transactionID: String): TipHistoryItem? {
        return load().firstOrNull { it.transactionID == transactionID }
    }

    @Synchronized
    fun upsert(
        transactionID: String,
        productID: String,
        displayPrice: String,
        purchasedAtMillis: Long,
        name: String? = null,
        message: String? = null,
        jws: String,
        appVersion: String,
    ): Pair<TipHistoryItem, Boolean> {
        val items = load().toMutableList()
        val index = items.indexOfFirst { it.transactionID == transactionID }
        if (index >= 0) {
            val existing = items[index]
            val next = existing.copy(
                name = name ?: existing.name,
                message = message ?: existing.message,
                displayPrice = if (existing.displayPrice.isEmpty() && displayPrice.isNotEmpty()) {
                    displayPrice
                } else {
                    existing.displayPrice
                },
                // Play 重放同一笔时会给新的凭据。留着旧的等于上报时拿一张过期的票。
                jws = jws.ifEmpty { existing.jws },
                purchasedAtMillis = if (purchasedAtMillis > 0) purchasedAtMillis else existing.purchasedAtMillis,
                appVersion = appVersion.ifEmpty { existing.appVersion },
            )
            items[index] = next
            save(items)
            return next to false
        }
        val created = TipHistoryItem(
            transactionID = transactionID,
            productID = productID,
            displayPrice = displayPrice,
            purchasedAtMillis = purchasedAtMillis,
            name = name,
            message = message,
            isSubmitted = false,
            jws = jws,
            appVersion = appVersion,
        )
        items.add(created)
        save(items)
        return created to true
    }

    @Synchronized
    fun updateDraft(transactionID: String, name: String?, message: String?) {
        val items = load().toMutableList()
        val index = items.indexOfFirst { it.transactionID == transactionID }
        if (index < 0) return
        items[index] = items[index].copy(name = name, message = message)
        save(items)
    }

    @Synchronized
    fun markSubmitted(transactionID: String) {
        val items = load().toMutableList()
        val index = items.indexOfFirst { it.transactionID == transactionID }
        if (index < 0) return
        items[index] = items[index].copy(isSubmitted = true)
        save(items)
    }

    @Synchronized
    fun clear() {
        prefs.edit().clear().apply()
    }

    private fun load(): List<TipHistoryItem> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList(array.length()) {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        TipHistoryItem(
                            transactionID = obj.getString("transactionID"),
                            productID = obj.getString("productID"),
                            displayPrice = obj.optString("displayPrice"),
                            purchasedAtMillis = obj.optLong("purchasedAt"),
                            name = obj.optString("name").takeIf { it.isNotEmpty() },
                            message = obj.optString("message").takeIf { it.isNotEmpty() },
                            isSubmitted = obj.optBoolean("isSubmitted"),
                            jws = obj.optString("jws"),
                            appVersion = obj.optString("appVersion"),
                        ),
                    )
                }
            }
        }.getOrElse { emptyList() }
    }

    private fun save(items: List<TipHistoryItem>) {
        val array = JSONArray()
        for (item in items) {
            array.put(
                JSONObject().apply {
                    put("transactionID", item.transactionID)
                    put("productID", item.productID)
                    put("displayPrice", item.displayPrice)
                    put("purchasedAt", item.purchasedAtMillis)
                    if (item.name != null) put("name", item.name)
                    if (item.message != null) put("message", item.message)
                    put("isSubmitted", item.isSubmitted)
                    put("jws", item.jws)
                    put("appVersion", item.appVersion)
                },
            )
        }
        prefs.edit().putString(KEY, array.toString()).apply()
    }

    companion object {
        private const val PREFS = "tollcat.tips"
        private const val KEY = "records"

        fun clear(context: Context) {
            TipStore(context).clear()
        }
    }
}
