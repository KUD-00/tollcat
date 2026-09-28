package com.zhechengqi.tollcat.setup

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context

fun copyText(context: Context, value: String, label: String = "tollcat") {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(ClipData.newPlainText(label, value))
}

/**
 * 只取纯文本。coerceToText 遇到只有 content:// / file:// URI 的条目，会以本 app
 * 的身份去打开那个 URI 读文本——别的 app 往剪贴板塞一个 URI，用户一粘贴，
 * 我们就替它读了自己能读到的 provider / 文件。
 */
fun pasteClipboard(context: Context): String? {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = clipboard.primaryClip ?: return null
    if (clip.itemCount <= 0) return null
    return clip.getItemAt(0).text?.toString()?.trim()
}
