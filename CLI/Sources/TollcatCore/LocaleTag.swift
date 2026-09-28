import Foundation

enum LocaleTag {
    /// `LANG` / `LC_ALL` / `--locale` → 传给 Product* 的 languageTag。
    static func resolve(explicit: String?, environment: [String: String]) -> String {
        if let explicit, !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return normalize(explicit)
        }
        let raw = environment["LC_ALL"].flatMap(nonC)
            ?? environment["LC_MESSAGES"].flatMap(nonC)
            ?? environment["LANG"].flatMap(nonC)
            ?? "zh-Hans"
        return normalize(raw)
    }

    static func normalize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let primary = trimmed.split(separator: ".").first.map(String.init) ?? trimmed
        let dashed = primary.replacingOccurrences(of: "_", with: "-")
        let lower = dashed.lowercased()
        if lower.hasPrefix("zh-hans") || lower.hasPrefix("zh-cn") || lower == "zh" {
            return "zh-Hans"
        }
        if lower.hasPrefix("zh-hant") || lower.hasPrefix("zh-tw") || lower.hasPrefix("zh-hk") {
            return "zh-Hant"
        }
        if lower.hasPrefix("en") {
            return "en"
        }
        if lower.hasPrefix("ja") {
            return "ja"
        }
        return dashed
    }

    private static func nonC(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        let language = trimmed.split(separator: ".").first.map(String.init) ?? trimmed
        if language == "C" || language == "POSIX" { return nil }
        return trimmed
    }
}
