import Foundation

/// 目录文案的语言列。中文是规范字段；`en` / `ja` 是 overlay。
///
/// 打包目录必须三语列齐，测试卡住。`localized(for:)` 遇到旧缓存缺列才回落中文，
/// 那不是翻译完成标准。不回落英文：法德用户缺列时看到源语言，不要再掺第三种。
///
/// 不在解码时拍扁：缓存和远程目录要带着所有列，换语言不必重拉。
/// locale 用语言标签字符串，不用 `Locale.current`：`MeterCore` 编进 Android .so，
/// 那边 JNI 入口的 locale 从 Kotlin 进来，和金额格式化同一条规矩。
public enum CatalogLanguage: String, Sendable, Hashable {
    case zh
    case en
    case ja

    /// `en`, `en-US`, `en_US` → 英文；`ja` / `ja-JP` → 日文；其余（含 `zh-Hans`）→ 中文。
    public static func resolving(localeTag: String) -> CatalogLanguage {
        let normalized = localeTag.replacingOccurrences(of: "_", with: "-").lowercased()
        if normalized == "en" || normalized.hasPrefix("en-") {
            return .en
        }
        if normalized == "ja" || normalized.hasPrefix("ja-") {
            return .ja
        }
        return .zh
    }

    public func pick<T>(en: T?, ja: T?) -> T? {
        switch self {
        case .zh: return nil
        case .en: return en
        case .ja: return ja
        }
    }
}

func catalogOverlay(_ value: String?, fallback: String) -> String {
    if let value, !value.isEmpty { return value }
    return fallback
}

func catalogOverlay(_ value: String?, fallback: String?) -> String? {
    if let value, !value.isEmpty { return value }
    return fallback
}
