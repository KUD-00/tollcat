import Foundation

/// 一个 target 的文案出处。
///
/// - 设了 `PortableLocale.languageTag`：查 `table`（生成器从这个 target 的
///   Localizable.xcstrings 抄出来，GENERATED，别手改），四个平台同一份结果。
/// - 没设、在 Apple 平台：交给这个 target 的 String Catalog，和系统设置走。
/// - 没设、在别的平台：原样出中文源串（桥总会设，这条只兜底）。
public struct PortableCatalog: Sendable {
    let table: [String: PortableTranslation]
    #if canImport(Darwin)
    let bundleURL: @Sendable () -> URL
    #endif

    #if canImport(Darwin)
    public init(table: [String: PortableTranslation], bundleURL: @escaping @Sendable () -> URL) {
        self.table = table
        self.bundleURL = bundleURL
    }
    #else
    public init(table: [String: PortableTranslation]) {
        self.table = table
    }
    #endif

    public func resolve(_ text: PortableText) -> String {
        if let tag = PortableLocale.languageTag {
            return PortableFormat.render(pattern(for: text.key, languageTag: tag), text.arguments)
        }
        #if canImport(Darwin)
        return String(localized: LocalizedStringResource(text.localizationValue, bundle: .atURL(bundleURL())))
        #else
        return PortableFormat.render(text.key, text.arguments)
        #endif
    }

    /// languageTag 前缀匹配；表里没有或语言对不上就回落中文源串。
    func pattern(for key: String, languageTag: String) -> String {
        guard let entry = table[key] else { return key }
        if languageTag.hasPrefix("en") { return entry.en }
        if languageTag.hasPrefix("ja") { return entry.ja }
        return key
    }
}
