import Foundation

/// 汇率表。**只有数字,没有网络。**
///
/// 来源是 `catalog.json` —— 目录只许带文字和数字,汇率正好是数字,所以它能远程
/// 更新而不违反那条红线。几天的滞后对「我这个月花了多少」完全够用;要精确到分的
/// 人应该去看厂商后台,那也是详情页「去官网处理」存在的理由。
///
/// 表里没有的币种一律换不出来 —— 宁可显示「这次没读到」,也不要按一个猜的汇率
/// 记一笔进总数。
public struct ExchangeRates: Hashable, Sendable {
    /// 1 单位该币种等于多少美元。`CNY: 0.14` 意思是 ¥1 ≈ $0.14。
    private let usdPerUnit: [String: Decimal]

    public init(usdPerUnit: [String: Decimal]) {
        self.usdPerUnit = Dictionary(
            usdPerUnit.map { (Self.normalized($0.key), $0.value) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// 只认美元。没有汇率表时的默认,行为和以前一样：非美元直接换不出来。
    public static let usdOnly = ExchangeRates(usdPerUnit: [:])

    public static let usdCode = "USD"

    /// 换不出来返回 nil，调用方决定是报错还是跳过。
    public func toUSD(_ amount: Decimal, from currency: String?) -> ConvertedAmount? {
        let code = Self.normalized(currency ?? Self.usdCode)
        if code.isEmpty || code == Self.usdCode {
            return ConvertedAmount(currency: Self.usdCode, amount: amount, usdPerUnit: 1)
        }
        guard let rate = usdPerUnit[code], rate > 0 else { return nil }
        var product = amount * rate
        var rounded = Decimal()
        // 换算到分。再往下的精度是假的，汇率本身只有四五位有效数字。
        NSDecimalRound(&rounded, &product, 2, .plain)
        return ConvertedAmount(currency: code, amount: amount, usdPerUnit: rate, usd: rounded)
    }

    /// 展示用：美元折回用户选的币。表里没有这个币就换不出来。
    public func fromUSD(_ amount: Decimal, to currency: String?) -> Decimal? {
        let code = Self.normalized(currency ?? Self.usdCode)
        if code.isEmpty || code == Self.usdCode {
            return amount
        }
        guard let rate = usdPerUnit[code], rate > 0 else { return nil }
        var quotient = amount / rate
        var rounded = Decimal()
        NSDecimalRound(&rounded, &quotient, CurrencyAmountFormat.fractionDigits(for: code), .plain)
        return rounded
    }

    public func supports(_ currency: String?) -> Bool {
        toUSD(1, from: currency) != nil
    }

    public var knownCurrencies: Set<String> {
        Set(usdPerUnit.keys).union([Self.usdCode])
    }

    /// 设置里的选项：美元永远第一，其余按代码排。
    public var displayCodes: [String] {
        [Self.usdCode] + usdPerUnit.keys.sorted()
    }

    public static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
