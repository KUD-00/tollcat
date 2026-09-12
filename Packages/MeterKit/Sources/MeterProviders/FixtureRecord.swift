import Foundation
import MeterCore

/// Fixture JSON 的解码形状。日期只记「当月第几天」，真正的 `Date` 在加载时按 `now` 展开。
struct FixtureRecord: Decodable, Sendable {
    var providerID: ProviderID
    var kind: ProviderKind
    var connected: Bool
    var currentSpendUSD: Double?
    var balanceUSD: Double?
    var committedMonthlyUSD: Double?
    var chargeDayOfMonth: Int?
    var freeQuotaUsedRatio: Double?
    var periodStartDayOfMonth: Int?
    var periodEndDayOfMonth: Int?
    var daily: [Daily]?
    var history: [History]?
    var lines: [Line]?
    var previousMonth: PreviousMonth?
    /// 上月再往前的整月读数。`monthsBack` 从 2 起；1 仍走 `previousMonth`，避免和同期对比那条抢。
    var olderMonths: [PreviousMonth]?

    struct Daily: Decodable, Sendable {
        var dayOfMonth: Int?
        var fromDay: Int?
        var toDay: Int?
        var usd: Double
    }

    /// 演示用的本账期明细。字段和 `SpendLine` 一一对应，金额用 `Double` 是
    /// 因为整个 fixture 层都这么写——演示数字不进对账，不需要 `Decimal` 的分位保证。
    struct Line: Decodable, Sendable {
        var category: String
        var label: String
        var scope: String?
        var usd: Double
        var listUSD: Double?
        var quantity: Double?
        var unit: String?
        var allowanceNote: String?

        var materialized: SpendLine {
            SpendLine(
                category: category,
                label: label,
                scope: scope,
                amountUSD: Money(roundedUSD: usd),
                listUSD: listUSD.map(Money.init(roundedUSD:)),
                quantity: quantity.map { Decimal($0) },
                unit: unit,
                allowanceNote: allowanceNote
            )
        }
    }

    struct History: Decodable, Sendable {
        var dayOfMonth: Int?
        var daysAgo: Int?
        var sameDayAsNow: Bool?
        var balanceUSD: Double
    }

    /// 往前回看某个月的读数。日期按 `now` 往前推 `monthsBack` 个月展开，不写死 7 月。
    struct PreviousMonth: Decodable, Sendable {
        /// 缺省 1 = 上月。`olderMonths` 里必须 ≥ 2。
        var monthsBack: Int?
        var currentSpendUSD: Double?
        var balanceUSD: Double?
        var committedMonthlyUSD: Double?
        var chargeDayOfMonth: Int?
        var freeQuotaUsedRatio: Double?
        var periodStartDayOfMonth: Int?
        var periodEndDayOfMonth: Int?
        var daily: [Daily]?
        var history: [History]?

        var hasPeriodMetrics: Bool {
            currentSpendUSD != nil
                || balanceUSD != nil
                || committedMonthlyUSD != nil
                || freeQuotaUsedRatio != nil
                || !(daily ?? []).isEmpty
        }
    }

    static func expandedDailyAmounts(_ specs: [Daily]?) -> [Int: Double] {
        var amounts: [Int: Double] = [:]
        for spec in specs ?? [] {
            if let day = spec.dayOfMonth {
                amounts[day, default: 0] += spec.usd
                continue
            }
            let start = spec.fromDay ?? spec.toDay
            let end = spec.toDay ?? spec.fromDay
            guard let start, let end, start <= end else { continue }
            for day in start...end {
                amounts[day, default: 0] += spec.usd
            }
        }
        return amounts
    }
}
