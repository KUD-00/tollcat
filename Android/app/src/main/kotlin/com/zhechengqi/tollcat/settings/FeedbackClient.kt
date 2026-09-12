package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.JniGate
import com.zhechengqi.tollcat.MeterCoreNative
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

enum class FeedbackCategory(val raw: String) {
    Bug("bug"),
    Idea("idea"),
    Provider("provider"),
    Other("other"),
}

enum class FeedbackResult {
    Sent,
    RateLimited,
    Failed,
}

object FeedbackClient {
    const val MESSAGE_MAX = 2000
    const val CONTACT_MAX = 120

    fun submit(
        category: FeedbackCategory,
        message: String,
        contact: String,
        appVersion: String,
        osVersion: String,
        locale: String,
        deviceModel: String,
        providers: List<String>?,
    ): FeedbackResult {
        val trimmed = message.trim()
        if (trimmed.isEmpty()) return FeedbackResult.Failed
        val body = JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("category", category.raw)
            put("message", trimmed.take(MESSAGE_MAX))
            val trimmedContact = contact.trim()
            if (trimmedContact.isNotEmpty()) {
                put("contact", trimmedContact.take(CONTACT_MAX))
            }
            put("appVersion", appVersion.take(40))
            put("osVersion", osVersion.take(40))
            put("locale", locale.take(40))
            put("deviceModel", deviceModel.take(40))
            if (!providers.isNullOrEmpty()) {
                put("providers", JSONArray(providers))
            }
        }
        val json = try {
            JniGate.blocking { MeterCoreNative.postFeedbackJson(body.toString()) }
        } catch (_: Exception) {
            return FeedbackResult.Failed
        }
        return parseResult(json)
    }

    internal fun parseResult(json: String): FeedbackResult {
        return runCatching {
            val root = JSONObject(json)
            when {
                root.optBoolean("ok") -> FeedbackResult.Sent
                root.optBoolean("rateLimited") || root.optInt("status") == 429 -> FeedbackResult.RateLimited
                else -> FeedbackResult.Failed
            }
        }.getOrElse { FeedbackResult.Failed }
    }
}
