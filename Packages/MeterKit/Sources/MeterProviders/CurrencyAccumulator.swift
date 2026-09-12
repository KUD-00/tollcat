import Foundation
import MeterCore

/// 逐行累加金额时的币种收敛器。
///
/// **先按原币累加，最后统一换一次。** 每行各换一次会把换算的取整误差累起来——
/// 一个月上千行的话差得出来。
///
/// 一次取数里混着两种币种直接拒：那种账户没法在「一个数字」里表达，
/// 与其糊一个和后台对不上的数，不如报错让用户去官网看。
struct CurrencyAccumulator: Sendable {
    private(set) var code: String?

    /// 每读到一行就报一次它的币种。
    mutating func observe(_ raw: String?, providerID: ProviderID) throws {
        try BillingCurrency.reconcile(&code, with: raw, providerID: providerID)
    }

    /// 累加完统一换。返回的 `ConvertedAmount` 要挂到 `Snapshot.converted` 上。
    func convert(
        _ amount: Decimal,
        rates: ExchangeRates,
        providerID: ProviderID
    ) throws -> ConvertedAmount {
        try BillingCurrency.convert(
            amount,
            currency: code,
            rates: rates,
            providerID: providerID
        )
    }

    /// 全程都是美元时不必在快照上留换算说明。
    var needsConversionNote: Bool {
        guard let code else { return false }
        return code != ExchangeRates.usdCode
    }

    /// 按原币累加的金额换成美元后，日线也要跟着按同一个汇率缩放，
    /// 否则日线加起来和合计对不上。
    func scaled(_ daily: [Date: Money]?, by rate: Decimal) -> [Date: Money]? {
        guard let daily, rate != 1 else { return daily }
        return daily.mapValues { Money(usd: ($0.usd * rate).roundedToCents) }
    }
}

private extension Decimal {
    var roundedToCents: Decimal {
        var value = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        return rounded
    }
}
