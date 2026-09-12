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
    /// 还没发过正式版。发版时在 shared/changelog.json 顶上加一条。
    static let entries: [WhatsNewEntry] = []
}
