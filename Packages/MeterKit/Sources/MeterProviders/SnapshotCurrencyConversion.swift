import Foundation
import MeterCore

extension Snapshot {
    /// 适配器按厂商**原币**把快照拼好，最后统一换成美元。
    ///
    /// 为什么放在收尾而不是逐行换：逐行换会把取整误差累起来，
    /// 而且日线各自换完加起来不等于合计——图和总数当场打脸。
    /// 这里所有金额字段乘同一个汇率，比例关系原样保住。
    ///
    /// 全程美元时原样返回，不给美元户平白挂一行换算说明。
    func convertedToUSD(
        using currency: CurrencyAccumulator,
        rates: ExchangeRates
    ) throws -> Snapshot {
        guard currency.needsConversionNote else { return self }

        let headline = headlineAmountForConversion
        let converted = try currency.convert(headline, rates: rates, providerID: providerID)
        let rate = converted.usdPerUnit

        var result = self
        result.currentSpendUSD = currentSpendUSD.map { $0.scaled(by: rate) }
        result.balanceUSD = balanceUSD.map { $0.scaled(by: rate) }
        result.committedMonthlyUSD = committedMonthlyUSD.map { $0.scaled(by: rate) }
        result.dailyUSD = currency.scaled(dailyUSD, by: rate)
        result.lines = lines?.map { $0.scaled(by: rate) }
        result.converted = converted
        return result
    }

    /// 换算说明里展示哪个数，按 kind 挑这家的主角金额。
    ///
    /// 用量经常只有日线、没有周期累计。这里若退回 0，`converted.usd == 0`，
    /// `isCurrencyConverted` 会把已经按汇率缩过的日线当成没换过币，
    /// 仪表总数就还是 `.exact`。
    private var headlineAmountForConversion: Decimal {
        switch kind {
        case .prepaid:
            return balanceUSD?.usd ?? 0
        case .subscription:
            return committedMonthlyUSD?.usd ?? 0
        case .usage, .planAndUsage:
            return currentSpendUSD?.usd ?? dailyTotalUSD
        case .freeTier:
            return currentSpendUSD?.usd ?? 0
        }
    }

    private var dailyTotalUSD: Decimal {
        dailyUSD?.values.reduce(0) { $0 + $1.usd } ?? 0
    }
}

private extension Money {
    func scaled(by rate: Decimal) -> Money {
        guard rate != 1 else { return self }
        return Money(usd: usd * rate).roundedToCents()
    }
}

private extension SpendLine {
    func scaled(by rate: Decimal) -> SpendLine {
        guard rate != 1 else { return self }
        var result = self
        result.amountUSD = amountUSD.scaled(by: rate)
        result.listUSD = listUSD.map { $0.scaled(by: rate) }
        return result
    }
}
