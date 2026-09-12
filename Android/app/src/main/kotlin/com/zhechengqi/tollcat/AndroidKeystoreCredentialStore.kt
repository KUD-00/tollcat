package com.zhechengqi.tollcat

import android.app.KeyguardManager
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.os.Build
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class AndroidKeystoreCredentialStore(context: Context) : CredentialStore {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** 设备现在有没有安全锁屏（PIN / 图案 / 密码）。两种绑定都以它为前提。 */
    private val deviceIsSecure: Boolean
        get() = runCatching {
            (appContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isDeviceSecure
        }.getOrDefault(false)

    override fun save(secret: String, reference: String) {
        prefs.edit().putString(reference, encrypt(secret)).apply()
    }

    override fun read(reference: String): String? {
        val packed = prefs.getString(reference, null) ?: return null
        return decrypt(packed)
    }

    override fun delete(reference: String) {
        prefs.edit().remove(reference).apply()
    }

    override fun deleteAll() {
        prefs.edit().clear().apply()
    }

    private fun encrypt(plain: String): String = encryptWith(secretKey(), plain)

    private fun decrypt(packed: String): String = decryptWith(secretKey(), packed)

    // 下面两个显式收密钥：轮换时要用**旧**密钥解、**新**密钥加，不能再走
    // secretKey()（那会递归回轮换逻辑）。
    private fun encryptWith(key: SecretKey, plain: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val iv = cipher.iv
        val bytes = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        val packed = ByteArray(iv.size + bytes.size)
        System.arraycopy(iv, 0, packed, 0, iv.size)
        System.arraycopy(bytes, 0, packed, iv.size, bytes.size)
        return Base64.encodeToString(packed, Base64.NO_WRAP)
    }

    private fun decryptWith(key: SecretKey, packed: String): String {
        val raw = Base64.decode(packed, Base64.NO_WRAP)
        require(raw.size > IV_BYTES)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            key,
            GCMParameterSpec(TAG_BITS, raw, 0, IV_BYTES),
        )
        val bytes = cipher.doFinal(raw, IV_BYTES, raw.size - IV_BYTES)
        return String(bytes, Charsets.UTF_8)
    }

    /// 这把包裹密钥当前是否真的绑定了「设备已解锁」。
    ///
    /// `setUnlockedDeviceRequired(true)` 从 API 28 起就能调，但 Keystore
    /// **从 API 31 才可靠拒绝锁屏期间的使用**。在 28–30 上只调它等于没有绑定：
    /// 进程还活着（或同 UID / root 的取证代码）在锁屏后仍能 `Cipher.init`
    /// 解开 prefs 里的信封。那一段改用「解锁后 N 秒内可用」的用户认证绑定
    /// 来补——它不是每次用都弹框，只要求设备有安全锁屏且最近解锁过。
    ///
    /// 设备没有安全锁屏时两种绑定都立不起来，此时退回无绑定的密钥并把
    /// 这个值置为 false，让调用方能看见真实保证，而不是以为已经对齐 iOS。
    @Volatile
    var boundToUnlockedDevice: Boolean = true
        private set

    private fun secretKey(): SecretKey {
        val store = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (store.getEntry(ALIAS, null) as? KeyStore.SecretKeyEntry)?.secretKey?.let { existing ->
            // 已有的那把是哪种规格建的，Keystore 不直接告诉我们，所以建的时候
            // 记一笔。没有这笔记录（旧版本装上来的）按未绑定算，宁可低报。
            boundToUnlockedDevice = prefs.getBoolean(BOUND_FLAG, false)
            // 首次启动时设备还没设锁屏 → 当时只能建无绑定的密钥。用户后来设了 PIN，
            // 旧实现会一直用那把没有绑定的，等于这台机器上的保证永远升不回来。
            // 这里补一次轮换：换新别名重新加密全部信封，成功后删掉旧密钥。
            if (!boundToUnlockedDevice && deviceIsSecure) {
                rotateToBoundKey(store, existing)?.let { return it }
            }
            return existing
        }
        // 先按能立起绑定的规格建；设备没有安全锁屏会抛，再退回无绑定的。
        val key = runCatching { generateKey(bound = true) }
            .getOrElse {
                boundToUnlockedDevice = false
                generateKey(bound = false)
            }
        prefs.edit().putBoolean(BOUND_FLAG, boundToUnlockedDevice).apply()
        return key
    }

    /**
     * 把全部信封从 [old] 解出来、建一把有绑定的新密钥、再逐条加密写回。
     *
     * 只在**全部**信封都成功重加密之后才落盘并删旧密钥；中途任一条失败就整体放弃，
     * 保持旧密钥与旧密文可用——宁可保证弱一点，也不能把用户的凭据弄成解不开的砖。
     */
    private fun rotateToBoundKey(store: KeyStore, old: SecretKey): SecretKey? = runCatching {
        val envelopes = prefs.all
            .filterKeys { it != BOUND_FLAG }
            .mapNotNull { (reference, packed) ->
                (packed as? String)?.let { reference to decryptWith(old, it) }
            }
        store.deleteEntry(ALIAS)
        val fresh = generateKey(bound = true)
        val reencrypted = envelopes.associate { (reference, plain) -> reference to encryptWith(fresh, plain) }
        prefs.edit().apply {
            for ((reference, packed) in reencrypted) putString(reference, packed)
            putBoolean(BOUND_FLAG, true)
        }.apply()
        boundToUnlockedDevice = true
        fresh
    }.getOrNull()

    private fun generateKey(bound: Boolean): SecretKey {
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
        if (bound) {
            // 对齐 iOS 的 WhenUnlockedThisDeviceOnly。31+ 这一条自己就够。
            spec.setUnlockedDeviceRequired(true)
            // 28–30 的补偿手段要求设备有安全锁屏；没有就让它抛，由调用方退回无绑定。
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                // 28–30：Keystore 不强制执行上面那条，用「最近解锁过」补上。
                // 时长 > 0 表示解锁后这段时间内直接可用，不逐次弹框。
                spec.setUserAuthenticationRequired(true)
                @Suppress("DEPRECATION")
                spec.setUserAuthenticationValidityDurationSeconds(UNLOCK_VALIDITY_SECONDS)
            }
        }
        generator.init(spec.build())
        return generator.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val ALIAS = "cat.toll.credentials"
        const val PREFS = "tollcat.credentials"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_BYTES = 12
        const val TAG_BITS = 128
        // 解锁后多久内这把密钥仍可用（28–30 的绑定手段）。
        const val UNLOCK_VALIDITY_SECONDS = 600
        // 建密钥时记下它到底有没有立起解锁绑定，读回来才不会谎报保证。
        const val BOUND_FLAG = "credentials.boundToUnlockedDevice"
    }
}
