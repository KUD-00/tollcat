package com.zhechengqi.tollcat.settings

import java.util.Locale

/** 隐私、支持和源码。编译死在 App 里，不从远程目录来。 */
object LegalURL {
    const val SOURCE = "https://github.com/KUD-00/tollcat"

    fun privacy(languageCode: String? = Locale.getDefault().language): String =
        page("privacy", languageCode)

    fun support(languageCode: String? = Locale.getDefault().language): String =
        page("support", languageCode)

    fun page(slug: String, languageCode: String?): String {
        // 域名和路径拆开写：出站闸按引号里的 URL 抽 host，Kotlin 插值会把变量名吃进域名。
        return "https://tollcat.app" + pathPrefix(languageCode) + "/" + slug + "/"
    }

    fun pathPrefix(languageCode: String?): String {
        return when (languageCode) {
            "en" -> "/en"
            "ja" -> "/ja"
            else -> ""
        }
    }
}
