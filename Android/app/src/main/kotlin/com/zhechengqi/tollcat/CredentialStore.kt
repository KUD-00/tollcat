package com.zhechengqi.tollcat

/**
 * 对齐 `MeterPersistence.CredentialStore`。Kotlin UI 只认协议；密钥进 Android Keystore。
 */
interface CredentialStore {
    fun save(secret: String, reference: String)
    fun read(reference: String): String?
    fun delete(reference: String)
    fun deleteAll()
}
