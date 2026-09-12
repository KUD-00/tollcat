package com.zhechengqi.tollcat.share

import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import androidx.core.content.FileProvider
import java.io.File

/** 把本月合计卡写成 PNG，走系统 Sharesheet。不再取一次账单。 */
object ShareCardExporter {
    fun share(context: Context, content: ShareCardContent, chooserTitle: String) {
        val bitmap = ShareCardBitmap.render(content)
        val dir = File(context.cacheDir, "share").apply { mkdirs() }
        val file = File(dir, "tollcat-share.png")
        file.outputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        if (!bitmap.isRecycled) bitmap.recycle()
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.share",
            file,
        )
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri("share", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(send, chooserTitle).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (context !is Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(chooser)
    }
}
