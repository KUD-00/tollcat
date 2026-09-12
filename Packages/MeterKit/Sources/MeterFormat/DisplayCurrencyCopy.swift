import Foundation
import MeterCore

// Android 的 swift-foundation 没有 LocalizedStringResource，这个文件不进 .so。
#if !os(Android)
/// 设置选项和 VoiceOver 用的币种名。代码本身不进 catalog。
public enum DisplayCurrencyCopy {
    public static func name(for code: String) -> LocalizedStringResource? {
        switch ExchangeRates.normalized(code) {
        case ExchangeRates.usdCode: return L("美元")
        case "CNY": return L("人民币")
        case "EUR": return L("欧元")
        case "GBP": return L("英镑")
        case "JPY": return L("日元")
        case "AUD": return L("澳元")
        case "CAD": return L("加元")
        case "SGD": return L("新加坡元")
        case "INR": return L("卢比")
        case "BRL": return L("雷亚尔")
        case "KRW": return L("韩元")
        case "TWD": return L("新台币")
        case "HKD": return L("港币")
        default: return nil
        }
    }

    public static func localizedName(for code: String) -> String {
        if let name = name(for: code) {
            return String(localized: name)
        }
        return ExchangeRates.normalized(code)
    }

    public static func pickerLabel(for code: String) -> String {
        "\(localizedName(for: code)) (\(ExchangeRates.normalized(code)))"
    }

    public static func shownAs(_ code: String) -> String {
        String(localized: L("按 \(localizedName(for: code)) 显示"))
    }
}
#endif
