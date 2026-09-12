package com.zhechengqi.tollcat.settings

import com.zhechengqi.tollcat.JniGate
import com.zhechengqi.tollcat.MeterCoreNative
import org.json.JSONObject

data class InboxProvisioning(
    val mailbox: String,
    val readKey: String,
    val ingestKey: String,
    val ingestKeyId: String,
)

data class IngestKeyInfo(
    val id: String,
    val label: String,
    val lastUsedAt: String? = null,
)

enum class InboxFailure {
    RateLimited,
    Unauthorized,
    Unreachable,
    Malformed,
}

class InboxException(val failure: InboxFailure) : Exception(failure.name)

object InboxClient {
    fun create(): InboxProvisioning {
        val body = request { MeterCoreNative.inboxCreateJson() }
        val mailbox = body.optString("mailbox")
        val readKey = body.optString("readKey")
        val ingest = body.optString("ingestKey")
        val ingestId = body.optString("ingestKeyID")
        if (mailbox.isBlank() || readKey.isBlank() || ingest.isBlank()) {
            throw InboxException(InboxFailure.Malformed)
        }
        return InboxProvisioning(mailbox, readKey, ingest, ingestId)
    }

    fun delete(readKey: String) {
        request { MeterCoreNative.inboxDeleteJson(readKey) }
    }

    fun listKeys(readKey: String): List<IngestKeyInfo> {
        val body = request { MeterCoreNative.inboxListKeysJson(readKey) }
        val keys = body.optJSONArray("keys") ?: return emptyList()
        return (0 until keys.length()).mapNotNull { index ->
            val item = keys.optJSONObject(index) ?: return@mapNotNull null
            val id = item.optString("id")
            if (id.isBlank()) null else IngestKeyInfo(
                id = id,
                label = item.optString("label"),
                lastUsedAt = item.optString("lastUsedAt").takeIf { it.isNotBlank() },
            )
        }
    }

    fun mint(readKey: String, label: String): Pair<String, String> {
        val body = request { MeterCoreNative.inboxMintKeyJson(readKey, label) }
        val secret = body.optString("ingestKey")
        val id = body.optString("ingestKeyID")
        if (secret.isBlank() || id.isBlank()) throw InboxException(InboxFailure.Malformed)
        return id to secret
    }

    fun revoke(readKey: String, id: String) {
        request { MeterCoreNative.inboxRevokeKeyJson(readKey, id) }
    }

    private fun request(block: () -> String): JSONObject {
        val root = runCatching { JSONObject(JniGate.blocking(block)) }
            .getOrElse { throw InboxException(InboxFailure.Unreachable) }
        if (root.optBoolean("rateLimited") || root.optInt("status") == 429) {
            throw InboxException(InboxFailure.RateLimited)
        }
        val status = root.optInt("status")
        if (status == 401 || status == 403) throw InboxException(InboxFailure.Unauthorized)
        if (!root.optBoolean("ok", status in 200..299)) {
            throw InboxException(InboxFailure.Unreachable)
        }
        return root.optJSONObject("body") ?: JSONObject()
    }
}
