// GENERATED — 由 scripts/generate-shared.py 从 Packages/MeterKit/Sources/MeterFormat/Resources/Localizable.xcstrings 生成。
// 不要手改：改 Packages/MeterKit/Sources/MeterFormat/Resources/Localizable.xcstrings 后重跑生成器。


import Foundation

/// MeterFormat 的文案出处（见 `PortableCatalog`）：键是中文源串，值是 en / ja。
/// 桥上设了 `PortableLocale.languageTag` 时查这张表；Apple 平台不设时走 String Catalog。
enum MeterFormatCopy {
    static let catalog: PortableCatalog = {
        #if canImport(Darwin)
        PortableCatalog(table: table, bundleURL: { Bundle.module.bundleURL })
        #else
        PortableCatalog(table: table)
        #endif
    }()

    private static let table: [String: PortableTranslation] = [
        "%@ %@": PortableTranslation(en: "%@ %@", ja: "%@ %@"),
        "%lld 美元": PortableTranslation(en: "%lld dollars", ja: "%lld ドル"),
        "%lld 美元 %lld 美分": PortableTranslation(en: "%1$lld dollars and %2$lld cents", ja: "%1$lld ドル %2$lld セント"),
        "%lld 美分": PortableTranslation(en: "%lld cents", ja: "%lld セント"),
        "0 美元": PortableTranslation(en: "0 dollars", ja: "0 ドル"),
        "人民币": PortableTranslation(en: "Chinese yuan", ja: "人民元"),
        "今天": PortableTranslation(en: "Today", ja: "今日"),
        "刚刚": PortableTranslation(en: "Just now", ja: "たった今"),
        "加元": PortableTranslation(en: "Canadian dollar", ja: "カナダドル"),
        "卢比": PortableTranslation(en: "Indian rupee", ja: "インドルピー"),
        "按 %@ 显示": PortableTranslation(en: "Shown in %@", ja: "%@ で表示"),
        "新加坡元": PortableTranslation(en: "Singapore dollar", ja: "シンガポールドル"),
        "新台币": PortableTranslation(en: "New Taiwan dollar", ja: "新台湾ドル"),
        "日元": PortableTranslation(en: "Japanese yen", ja: "円"),
        "明天": PortableTranslation(en: "Tomorrow", ja: "明日"),
        "欧元": PortableTranslation(en: "Euro", ja: "ユーロ"),
        "港币": PortableTranslation(en: "Hong Kong dollar", ja: "香港ドル"),
        "澳元": PortableTranslation(en: "Australian dollar", ja: "豪ドル"),
        "美元": PortableTranslation(en: "US dollar", ja: "米ドル"),
        "英镑": PortableTranslation(en: "British pound", ja: "ポンド"),
        "负 %@ %@": PortableTranslation(en: "minus %@ %@", ja: "マイナス %@ %@"),
        "负 %lld 美元": PortableTranslation(en: "negative %lld dollars", ja: "マイナス %lld ドル"),
        "负 %lld 美元 %lld 美分": PortableTranslation(en: "negative %1$lld dollars and %2$lld cents", ja: "マイナス %1$lld ドル %2$lld セント"),
        "负 %lld 美分": PortableTranslation(en: "negative %lld cents", ja: "マイナス %lld セント"),
        "负 0 美元": PortableTranslation(en: "negative 0 dollars", ja: "マイナス 0 ドル"),
        "账号 1": PortableTranslation(en: "Account 1", ja: "アカウント 1"),
        "雷亚尔": PortableTranslation(en: "Brazilian real", ja: "レアル"),
        "韩元": PortableTranslation(en: "South Korean won", ja: "ウォン"),
    ]
}
