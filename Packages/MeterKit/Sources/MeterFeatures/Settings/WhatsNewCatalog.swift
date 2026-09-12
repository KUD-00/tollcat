// GENERATED — 由 scripts/generate-shared.py 从 shared/changelog.json 生成。
// 不要手改：改 shared/changelog.json 后重跑生成器。

import MeterDesign

/// 每一班车的更新说明。新的在上。
///
/// 三语都编在这里，展示时按 `CatalogLanguage` 选列——和目录同一条规矩，
/// 不走 xcstrings（那边是界面外壳的文案，这边是内容）。
///
/// **编译期，不下发。** 它描述的是正在跑的这个二进制，打 tag 那一刻就全部已知；
/// 而抽屉在「更新后第一次冷启动」弹，那一刻远程缓存里按定义没有这条。
/// 以后若要支持远程改错别字，能被覆盖的只有 `title` / `body`，按 `WhatsNewItem.id` 认。
enum WhatsNewCatalog {
    static let entries: [WhatsNewEntry] = [
        WhatsNewEntry(
            version: "1.0.0",
            platforms: [.ios],
            showsDrawer: false,
            hero: .cat(.normal),
            title: WhatsNewText(zh: "TollCat 1.0：云账单，装进口袋", en: "TollCat 1.0: your cloud bills, in your pocket", ja: "TollCat 1.0：クラウドの請求を、ポケットに"),
            items: [
                WhatsNewItem(
                    id: "firstRelease",
                    symbol: "sparkles",
                    title: WhatsNewText(zh: "第一版上架了", en: "The first release", ja: "はじめてのリリース"),
                    body: WhatsNewText(zh: "先从 iPhone 和 iPad 开始。把各家云和 AI 服务的花费加在一起，打开就能看到这个月到现在一共花了多少。", en: "iPhone and iPad first. TollCat adds up what you spend across your cloud and AI services, so one glance tells you how much this month has cost so far.", ja: "まずは iPhone と iPad から。クラウドや AI サービスの利用料をまとめて、今月ここまでいくら使ったかがひと目でわかります。")
                ),
            ]
        ),
    ]
}
