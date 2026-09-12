import Foundation
import MeterCore

/// 更新说明的三语文本。中文是规范列，`en` / `ja` 由生成器从 `shared/changelog.json` 铺齐。
///
/// 为什么不走 xcstrings：那边是界面外壳的文案（「知道了」这种，一次写好长期不动），
/// 这边是**内容**——一条一条按版本长出来，条数无上界，而且落地页和商店文案也要读同一份。
/// 和 `catalog.json` 同类，所以选列也走同一条规矩（`CatalogLanguage`）。
struct WhatsNewText: Hashable, Sendable {
    var zh: String
    var en: String
    var ja: String

    init(zh: String, en: String, ja: String) {
        self.zh = zh
        self.en = en
        self.ja = ja
    }

    func resolved(_ language: CatalogLanguage) -> String {
        switch language {
        case .zh: zh
        case .en: en
        case .ja: ja
        }
    }
}
