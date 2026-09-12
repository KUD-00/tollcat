import Foundation
import MeterCore

/// 厂商结算币种的入口。
///
/// **以前这里是「非美元一律拒绝」。** 那条规矩挡住的是真实用户：DeepSeek 和
/// Moonshot (China) 的国内户是人民币，Azure / Fastly 按账户所在地结算。现在改成按
/// `ExchangeRates` 换算，换不出来才拒。
///
/// 换算结果连同原币原值一起交给调用方，`Snapshot.converted` 要留着它——
/// 换出来的数字对不上厂商后台时，用户得能看出差在哪。
enum BillingCurrency: Sendable {
    /// 汇率表里没有这个币种就抛 `unsupportedCurrency`：宁可这次没读到，
    /// 也不要按一个猜的汇率记一笔进总数。
    static func convert(
        _ amount: Decimal,
        currency raw: String?,
        rates: ExchangeRates,
        providerID: ProviderID
    ) throws -> ConvertedAmount {
        guard let converted = rates.toUSD(amount, from: raw) else {
            throw ProviderError.unsupportedCurrency(providerID: providerID)
        }
        return converted
    }

    /// 一次取数里所有行必须同币种。混着来就没法先累加再换算，直接拒。
    static func reconcile(
        _ seen: inout String?,
        with raw: String?,
        providerID: ProviderID
    ) throws {
        let code = normalize(raw) ?? ExchangeRates.usdCode
        guard let seen else {
            seen = code
            return
        }
        guard seen == code else {
            throw ProviderError.unsupportedCurrency(providerID: providerID)
        }
    }

    static func normalize(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return trimmed.isEmpty ? nil : trimmed
    }
}
