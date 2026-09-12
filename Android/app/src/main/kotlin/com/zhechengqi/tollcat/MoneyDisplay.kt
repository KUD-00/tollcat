package com.zhechengqi.tollcat

import java.util.Locale

/**
 * 「说钱」的进程级上下文。金额格式化在 Swift 侧（`ProductFormat`），
 * 这里只持有显示币种和 locale，供不方便拿到 session 的纯函数使用。
 * `TollCatSession` 在启动和改币种时更新。
 */
object MoneyDisplay {
    @Volatile
    var currency: String = "USD"

    fun localeTag(): String = Locale.getDefault().toLanguageTag()

    /**
     * USD 十进制字符串 → 显示币种字符串。已经带符号的（JNI 返回的）原样退回。
     * `.so` 没装上（Compose 预览）时回落成 `$%.2f`，只影响预览。
     */
    fun formatUsd(raw: String): String {
        val trimmed = raw.trim()
        if (trimmed.isEmpty() || trimmed.toDoubleOrNull() == null) return trimmed
        if (!MeterCoreNative.loaded) {
            return "$" + "%.2f".format(trimmed.toDouble())
        }
        return MeterCoreNative.formatUsd(trimmed, currency, localeTag())
    }
}
