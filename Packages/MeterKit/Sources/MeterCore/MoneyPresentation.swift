import Foundation

/// 把账本里的美元写成用户选的货币。
///
/// 账本永远是美元。这一层只在展示时换，换不出来就退回美元——不要猜一个汇率。
public struct MoneyPresentation: Hashable, Sendable {
    public var currencyCode: String
    public var rates: ExchangeRates

    public static let usd = MoneyPresentation(currencyCode: ExchangeRates.usdCode, rates: .usdOnly)

    public init(currencyCode: String, rates: ExchangeRates) {
        let code = ExchangeRates.normalized(currencyCode)
        if rates.supports(code) {
            self.currencyCode = code
        } else {
            self.currencyCode = ExchangeRates.usdCode
        }
        self.rates = rates
    }

    public var isUSD: Bool {
        currencyCode == ExchangeRates.usdCode
    }

    public func amount(from money: Money) -> Decimal {
        rates.fromUSD(money.usd, to: currencyCode) ?? money.usd
    }

    /// `original` 的币种正好是正在显示的那种时，用厂商原值，避免折成美元再折回来差一分。
    public func string(from money: Money, original: ConvertedAmount? = nil) -> String {
        if let original, original.currency == currencyCode {
            return CurrencyAmountFormat.string(amount: original.amount, code: currencyCode)
        }
        return CurrencyAmountFormat.string(amount: amount(from: money), code: currencyCode)
    }

    /// 同上，但原币说明是两个标量（原币码 + 厂商自己报的汇率）而不是
    /// `ConvertedAmount`——`AccountLatest` 只存标量，见它的准入准则第 4 条。
    ///
    /// 原币金额由 `money ÷ usdPerUnit` 还原：折回去用的是**厂商的**汇率，
    /// 和拿着原值时是同一个数；用我们的汇率表折才会差一分。
    public func string(from money: Money, originalCurrency: String?, usdPerUnit: Decimal?) -> String {
        guard
            let originalCurrency,
            ExchangeRates.normalized(originalCurrency) == currencyCode,
            let usdPerUnit,
            usdPerUnit != 0
        else {
            return string(from: money)
        }
        return CurrencyAmountFormat.string(amount: money.usd / usdPerUnit, code: currencyCode)
    }

    /// 1 单位原币折成正在显示的那种钱。没换过币、或原币就是展示币时返回 nil——
    /// `1 CNY = ¥1` 没有信息量，大数字已经是原值。
    public func unitRateString(from original: ConvertedAmount) -> String? {
        guard original.isConverted else { return nil }
        let from = ExchangeRates.normalized(original.currency)
        guard from != currencyCode else { return nil }

        if isUSD {
            let digits = NSDecimalNumber(decimal: original.usdPerUnit).stringValue
            return "\(CurrencyAmountFormat.prefix(for: currencyCode))\(digits)"
        }
        guard let converted = rates.fromUSD(original.usdPerUnit, to: currencyCode) else {
            return nil
        }
        return CurrencyAmountFormat.string(amount: converted, code: currencyCode)
    }
}
