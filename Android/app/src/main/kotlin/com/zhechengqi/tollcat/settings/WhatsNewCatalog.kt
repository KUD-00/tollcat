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
    val entries: List<WhatsNewEntry> = listOf(
        WhatsNewEntry(
            version = "1.0.0",
            platforms = setOf("ios"),
            showsDrawer = false,
            hero = WhatsNewHero.Cat("normal"),
            title = WhatsNewText(zh = "TollCat 1.0：云账单，装进口袋", en = "TollCat 1.0: your cloud bills, in your pocket", ja = "TollCat 1.0：クラウドの請求を、ポケットに"),
            items = listOf(
                WhatsNewItem(
                    id = "firstRelease",
                    symbol = null,
                    title = WhatsNewText(zh = "第一版上架了", en = "The first release", ja = "はじめてのリリース"),
                    body = WhatsNewText(zh = "先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。", en = "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far.", ja = "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。"),
                ),
            ),
        ),
    )
}
