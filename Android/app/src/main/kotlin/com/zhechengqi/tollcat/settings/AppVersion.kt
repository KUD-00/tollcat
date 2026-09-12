package com.zhechengqi.tollcat.settings

import android.content.Context
import android.os.Build

/**
 * 用户可见版本号 `X.Y.Z`。更新说明面板拿它和「看到哪一版」比大小，
 * 所以不带 versionCode——那个是 CI run number，每次都变。
 */
fun appVersionShort(context: Context): String {
    val info = context.packageManager.getPackageInfo(context.packageName, 0)
    return info.versionName ?: "0.1.0"
}

fun appVersionCaption(context: Context): String {
    val info = context.packageManager.getPackageInfo(context.packageName, 0)
    val name = info.versionName ?: "0.1.0"
    val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        info.longVersionCode
    } else {
        @Suppress("DEPRECATION")
        info.versionCode.toLong()
    }
    return "$name ($code)"
}

fun androidOsVersion(): String {
    return "Android ${Build.VERSION.RELEASE}"
}

fun androidDeviceModel(): String {
    val manufacturer = Build.MANUFACTURER.orEmpty()
    val model = Build.MODEL.orEmpty()
    return if (model.startsWith(manufacturer, ignoreCase = true)) {
        model
    } else {
        "$manufacturer $model".trim()
    }
}
