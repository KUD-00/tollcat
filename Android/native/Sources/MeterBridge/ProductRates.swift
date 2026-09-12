import Foundation
import MeterCore

/// 目录汇率。唯一数字源是 `catalog.json`（经 `ProductCatalog.bundled` 加载）；
/// 加载失败退回只认美元，宁可不换算也不用一张会漂移的手抄表。
/// 账本仍是美元；只在写出字的时候换。
package enum ProductRates {
    package static let bundled: ExchangeRates = ProductCatalog.bundled?.exchangeRates ?? .usdOnly

    package static func presentation(_ currency: String) -> MoneyPresentation {
        MoneyPresentation(currencyCode: currency, rates: bundled)
    }
}
