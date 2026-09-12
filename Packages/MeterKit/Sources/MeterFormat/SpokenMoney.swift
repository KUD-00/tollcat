import Foundation
import MeterCore

// Android 的 swift-foundation 没有 LocalizedStringResource，这个文件不进 .so。
#if !os(Android)
/// VoiceOver 要读「47 美元 20 美分」，不能把 "$47.20" 念成一串符号。
public enum SpokenMoney {
    public static func label(
        for money: Money,
        presentation: MoneyPresentation = .usd
    ) -> String {
        if !presentation.isUSD {
            return convertedLabel(for: money, presentation: presentation)
        }
        var centsDecimal = money.roundedToCents().usd * 100
        var centsRounded = Decimal()
        NSDecimalRound(&centsRounded, &centsDecimal, 0, .plain)
        let cents = NSDecimalNumber(decimal: centsRounded).intValue
        let isNegative = cents < 0
        let absolute = abs(cents)
        let dollars = absolute / 100
        let remainder = absolute % 100

        if dollars == 0, remainder == 0 {
            return zero(isNegative: isNegative)
        }
        if dollars == 0 {
            return centsOnly(remainder, isNegative: isNegative)
        }
        if remainder == 0 {
            return dollarsOnly(dollars, isNegative: isNegative)
        }
        return dollarsAndCents(dollars, remainder, isNegative: isNegative)
    }

    private static func convertedLabel(
        for money: Money,
        presentation: MoneyPresentation
    ) -> String {
        let amount = CurrencyAmountFormat.digits(
            amount: presentation.amount(from: money),
            code: presentation.currencyCode
        )
        let name = DisplayCurrencyCopy.localizedName(for: presentation.currencyCode)
        let isNegative = presentation.amount(from: money) < 0
        if isNegative {
            return String(localized: L("负 \(amount) \(name)"))
        }
        return String(localized: L("\(amount) \(name)"))
    }

    private static func zero(isNegative: Bool) -> String {
        if isNegative {
            return String(localized: L("负 0 美元"))
        }
        return String(localized: L("0 美元"))
    }

    private static func centsOnly(_ cents: Int, isNegative: Bool) -> String {
        if isNegative {
            return String(localized: L("负 \(cents) 美分"))
        }
        return String(localized: L("\(cents) 美分"))
    }

    private static func dollarsOnly(_ dollars: Int, isNegative: Bool) -> String {
        if isNegative {
            return String(localized: L("负 \(dollars) 美元"))
        }
        return String(localized: L("\(dollars) 美元"))
    }

    private static func dollarsAndCents(
        _ dollars: Int,
        _ cents: Int,
        isNegative: Bool
    ) -> String {
        if isNegative {
            return String(localized: L("负 \(dollars) 美元 \(cents) 美分"))
        }
        return String(localized: L("\(dollars) 美元 \(cents) 美分"))
    }
}
#endif
