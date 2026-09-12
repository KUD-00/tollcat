import Foundation

/// 一笔换算过的金额：原币、原值、用的汇率。
///
/// **为什么要留原值。** 换算出来的数字对不上厂商后台那一栏,用户第一反应会是
/// 「这个 App 算错了」。详情页在大数字下面留一行汇率（「（1 CNY = $0.1404）」；
/// 右边是用户选的显示货币），多钱包再列出各槽原币。这是第 12.5 节那条
/// 「诚实性必须可查」的同一个道理。
///
/// 原币就是美元时 `usdPerUnit == 1`,`isConverted` 为 false —— 不该给美元户
/// 平白加一行说明。
public struct ConvertedAmount: Hashable, Sendable, Codable {
    /// ISO 4217 代码,大写。
    public var currency: String
    /// 厂商原样返回的金额,不换算。
    public var amount: Decimal
    /// 1 单位原币等于多少美元。
    public var usdPerUnit: Decimal
    public var usd: Decimal

    public init(currency: String, amount: Decimal, usdPerUnit: Decimal, usd: Decimal? = nil) {
        self.currency = currency
        self.amount = amount
        self.usdPerUnit = usdPerUnit
        self.usd = usd ?? amount * usdPerUnit
    }

    /// 真的换过币才算换算。美元原样通过不算。
    public var isConverted: Bool {
        currency != ExchangeRates.usdCode
    }

    public var money: Money { Money(usd: usd) }
}
