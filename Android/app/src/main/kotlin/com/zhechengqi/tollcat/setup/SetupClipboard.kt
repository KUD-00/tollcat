package com.zhechengqi.tollcat.setup

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context

fun copyText(context: Context, value: String, label: String = "tollcat") {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(ClipData.newPlainText(label, value))
}

fun pasteClipboard(context: Context): String? {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    return clipboard.primaryClip?.getItemAt(0)?.coerceToText(context)?.toString()?.trim()
}
