package com.zhechengqi.tollcat

import org.json.JSONObject

/**
 * 接入行上 iOS 有独立列、Android 收在 `transfer_extras` 里的字段。
 * 读写都走这里，避免各页自己拆 JSON、导出时把昵称/结束日弄丢。
 */
object AccountExtras {
    private const val NICKNAME = "nickname"
    private const val ARCHIVED_AT = "archivedAt"
    private const val FINGERPRINT = "remoteIdentityFingerprint"
    private const val INGEST_KEY_ID = "inboxIngestKeyID"
    private const val USES_INBOX = "usesInbox"
    private const val IS_ENABLED = "isEnabled"
    private const val APPLE_REF = 978_307_200.0

    fun nickname(account: AccountRow): String? =
        extras(account)?.optString(NICKNAME)?.trim()?.takeIf { it.isNotEmpty() }

    fun isArchived(account: AccountRow): Boolean = archivedAtMillis(account) != null

    fun archivedAtMillis(account: AccountRow): Long? {
        val json = extras(account) ?: return null
        if (!json.has(ARCHIVED_AT) || json.isNull(ARCHIVED_AT)) return null
        return when (val raw = json.get(ARCHIVED_AT)) {
            is Number -> appleRefToMillis(raw.toDouble())
            is String -> raw.toDoubleOrNull()?.let { appleRefToMillis(it) }
            else -> null
        }
    }

    fun fingerprint(account: AccountRow): String? =
        extras(account)?.optString(FINGERPRINT)?.takeIf { it.isNotBlank() }

    fun ingestKeyId(account: AccountRow): String? =
        extras(account)?.optString(INGEST_KEY_ID)?.takeIf { it.isNotBlank() }

    fun usesInbox(account: AccountRow): Boolean =
        extras(account)?.optBoolean(USES_INBOX, false) == true

    fun displayName(account: AccountRow, providerName: String): String {
        val nick = nickname(account)
        return if (nick.isNullOrBlank()) providerName else "$providerName · $nick"
    }

    fun withNickname(account: AccountRow, value: String?): AccountRow =
        put(account, NICKNAME, value?.trim()?.takeIf { it.isNotEmpty() })

    fun withArchivedAt(account: AccountRow, atMillis: Long?): AccountRow {
        var next = account
        next = put(next, ARCHIVED_AT, atMillis?.let { millisToAppleRef(it) })
        next = put(next, IS_ENABLED, if (atMillis == null) true else false)
        return next
    }

    fun withFingerprint(account: AccountRow, value: String?): AccountRow =
        put(account, FINGERPRINT, value?.takeIf { it.isNotBlank() })

    fun withInbox(account: AccountRow, ingestKeyId: String?): AccountRow {
        var next = put(account, INGEST_KEY_ID, ingestKeyId?.takeIf { it.isNotBlank() })
        next = put(next, USES_INBOX, ingestKeyId != null)
        return next
    }

    /**
     * `key=value` 用 NUL 连起来只在值里没有 NUL、键里没有 `=` 时才无歧义：否则
     * `{a: "b\u0000c=d"}` 和 `{a: "b", c: "d"}` 算出同一个指纹。真实凭据不会带这些字符，
     * 所以常规输入仍用原编码，已存的指纹继续可比；碰到它们才换成带长度前缀的编码
     * （以 `v2` + NUL 开头，原编码第一个 NUL 前必有 `=`，两种编码不会撞）。
     */
    fun fingerprintOf(fields: Map<String, String>): String {
        val rows = fields.entries.sortedBy { it.key }.map { it.key to it.value.trim() }
        val ambiguous = rows.any { (key, value) -> '\u0000' in key || '=' in key || '\u0000' in value }
        val joined = if (ambiguous) {
            "v2\u0000" + rows.joinToString("") { (key, value) -> "${key.length}:$key${value.length}:$value" }
        } else {
            rows.joinToString("\u0000") { (key, value) -> "$key=$value" }
        }
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        return digest.digest(joined.toByteArray(Charsets.UTF_8)).joinToString("") { byte -> "%02x".format(byte) }
    }

    private fun extras(account: AccountRow): JSONObject? {
        val raw = account.transferExtrasJson ?: return null
        return runCatching { JSONObject(raw) }.getOrNull()
    }

    private fun put(account: AccountRow, key: String, value: Any?): AccountRow {
        val json = extras(account) ?: JSONObject()
        if (value == null) json.remove(key) else json.put(key, value)
        return account.copy(transferExtrasJson = json.toString().takeIf { json.length() > 0 })
    }

    private fun appleRefToMillis(seconds: Double): Long =
        ((seconds + APPLE_REF) * 1000.0).toLong()

    private fun millisToAppleRef(millis: Long): Double =
        millis / 1000.0 - APPLE_REF
}
