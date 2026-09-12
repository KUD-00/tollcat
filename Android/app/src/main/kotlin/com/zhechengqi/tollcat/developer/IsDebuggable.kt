package com.zhechengqi.tollcat.developer

import android.content.Context
import android.content.pm.ApplicationInfo

fun isDebuggable(context: Context): Boolean {
    return context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
}
