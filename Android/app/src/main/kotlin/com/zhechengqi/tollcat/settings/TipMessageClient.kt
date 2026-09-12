package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.JniGate
import com.zhechengqi.tollcat.MeterCoreNative
import org.json.JSONObject

/**
 * 打赏留言离开设备时只带这些字段。账单凭据和账单数据不在这个 payload 里。
 *
 * 出口在桥上（`ProductWorker.tipJson`），和反馈、匿名计数同一条路——
 * 这一端不自己发 HTTP。
 */
data class TipMessagePayload(
    val transactionID: String,
    val jws: String,
    val productID: String,
    val displayPrice: String,
    val name: String?,
    val message: String?,
    val appVersion: String,
) {
    init {
        require(transactionID.isNotEmpty())
        require(productID.isNotEmpty())
    }

    companion object {
        fun of(
            transactionID: String,
            jws: String,
            productID: String,
            displayPrice: String,
            name: String?,
            message: String?,
            appVersion: String,
        ): TipMessagePayload {
            return TipMessagePayload(
                transactionID = transactionID,
                jws = jws,
                productID = productID,
                displayPrice = displayPrice,
                name = TipFieldLimits.clampName(name),
                message = TipFieldLimits.clampMessage(message),
                appVersion = appVersion.take(40),
            )
        }
    }
}

object TipMessageClient {
    fun submit(payload: TipMessagePayload): Boolean {
        val body = JSONObject().apply {
            put("transactionID", payload.transactionID)
            put("jws", payload.jws)
            put("productID", payload.productID)
            put("displayPrice", payload.displayPrice)
            payload.name?.let { put("name", it) }
            payload.message?.let { put("message", it) }
            put("appVersion", payload.appVersion)
        }
        val json = try {
            JniGate.blocking { MeterCoreNative.postTipJson(body.toString()) }
        } catch (_: Exception) {
            return false
        }
        return runCatching { JSONObject(json).optBoolean("ok") }.getOrElse { false }
    }
}
