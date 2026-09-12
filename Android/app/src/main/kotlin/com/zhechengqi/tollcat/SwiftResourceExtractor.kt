package com.zhechengqi.tollcat

import android.content.Context
import android.content.res.AssetManager
import java.io.File

object SwiftResourceExtractor {
    fun extract(context: Context): File {
        val dest = File(context.filesDir, "swiftpm")
        dest.mkdirs()
        copyAssetDir(context.assets, "swiftpm", dest, dest.canonicalFile)
        return findFixturesRoot(dest)
    }

    private fun findFixturesRoot(extracted: File): File {
        return extracted.walkTopDown().firstOrNull { it.isFile && it.name == "aws.json" }?.parentFile
            ?: extracted
    }

    private fun copyAssetDir(assets: AssetManager, path: String, dest: File, root: File) {
        val children = assets.list(path) ?: return
        if (children.isEmpty()) {
            dest.parentFile?.mkdirs()
            assets.open(path).use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            return
        }
        dest.mkdirs()
        for (child in children) {
            // AAPT 打进 APK 的名字不会长这样；防的是以后把 extract 对准
            // 下载来的资源包时，`..`/绝对路径把文件写出 filesDir/swiftpm。
            require(!child.contains('/') && !child.contains('\\') && child != "..") {
                "asset name is not a plain file name: $path/$child"
            }
            val target = File(dest, child)
            require(target.canonicalFile.path.startsWith(root.path + File.separator)) {
                "asset escapes extraction root: $path/$child"
            }
            copyAssetDir(assets, "$path/$child", target, root)
        }
    }
}
