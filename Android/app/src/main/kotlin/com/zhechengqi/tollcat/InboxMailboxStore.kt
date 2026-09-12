package com.zhechengqi.tollcat

import org.json.JSONObject

/**
 * 信箱的 mailbox + readKey。对齐 iOS 的 `MeterPersistence.InboxMailboxStore`。
 *
 * readKey 不是「偏好」，是一把能读走全部读数、删掉信箱、再签发投递 key 的凭据。
 * 早先它和外观、预算一起明文躺在 `tollcat.preferences` 的 XML 里，能读那个文件的
 * 本地攻击者（root、已解锁的取证镜像、debuggable 包的 run-as）就能接管信箱。
 * 现在走和账单密钥同一条路：[AndroidKeystoreCredentialStore] 的 AES-GCM 信封。
 *
 * 引用名和 iOS 一样钉死成 [CREDENTIAL_REFERENCE]——它是固定槽位，不像账单凭据那样
 * 一家一个。
 */
object InboxMailboxStore {
    /** 与 iOS `InboxMailboxStore.credentialReference` 必须一致。 */
    const val CREDENTIAL_REFERENCE = "inbox.mailbox"

    data class Mailbox(val mailbox: String, val readKey: String)

    fun read(credentials: CredentialStore): Mailbox? {
        val raw = credentials.read(CREDENTIAL_REFERENCE) ?: return null
        return runCatching {
            val json = JSONObject(raw)
            val mailbox = json.optString("mailbox")
            val readKey = json.optString("readKey")
            if (mailbox.isBlank() || readKey.isBlank()) null else Mailbox(mailbox, readKey)
        }.getOrNull()
    }

    fun save(credentials: CredentialStore, mailbox: String, readKey: String) {
        val json = JSONObject().put("mailbox", mailbox).put("readKey", readKey)
        credentials.save(json.toString(), CREDENTIAL_REFERENCE)
    }

    fun delete(credentials: CredentialStore) {
        credentials.delete(CREDENTIAL_REFERENCE)
    }

    /**
     * 旧版本把这对值明文写在 preferences 里。读到就搬进凭据店并把明文抹掉。
     * 返回搬迁后的值（没有旧值时返回 null）。
     */
    fun migrateFromPreferences(credentials: CredentialStore, preferences: PreferencesStore): Mailbox? {
        val mailbox = preferences.legacyInboxMailbox
        val readKey = preferences.legacyInboxReadKey
        if (mailbox.isBlank() || readKey.isBlank()) {
            preferences.clearLegacyInbox()
            return null
        }
        save(credentials, mailbox, readKey)
        preferences.clearLegacyInbox()
        return Mailbox(mailbox, readKey)
    }
}
