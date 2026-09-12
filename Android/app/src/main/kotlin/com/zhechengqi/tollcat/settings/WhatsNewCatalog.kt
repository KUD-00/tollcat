// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。


package com.zhechengqi.tollcat.settings

/** 更新说明的三语文本。中文是规范列，展示时按 locale 选。 */
data class WhatsNewText(val zh: String, val en: String, val ja: String) {
    fun resolve(language: String): String = when {
        language == "en" || language.startsWith("en-") -> en
        language == "ja" || language.startsWith("ja-") -> ja
        else -> zh
    }
}

/** 抽屉里的一条。`id` 稳定，改名等于换一条。 */
data class WhatsNewItem(
    val id: String,
    val symbol: String?,
    val title: WhatsNewText,
    val body: WhatsNewText,
)

sealed interface WhatsNewHero {
    data class Cat(val mood: String) : WhatsNewHero
    data class Glyph(val provider: String) : WhatsNewHero
    data class Shot(val name: String) : WhatsNewHero
}

data class WhatsNewEntry(
    val version: String,
    val platforms: Set<String>,
    val showsDrawer: Boolean,
    val hero: WhatsNewHero?,
    val title: WhatsNewText,
    val items: List<WhatsNewItem>,
)

/** 新的在上。编译期铺进来，不下发——理由见 shared/changelog.json 的注释。 */
object WhatsNewCatalog {
    val entries: List<WhatsNewEntry> = emptyList()
}
