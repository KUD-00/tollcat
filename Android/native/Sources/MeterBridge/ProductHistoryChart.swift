import Foundation
import MeterCore
import MeterProviders

/// 详情页历史图的视图状态。分桶、做差、推断段单源在 `HistoryChartMath`
/// （MeterCore，与 iOS 同一份）；这里只把结果和轴刻度铺成 JSON，
/// Kotlin 只渲染，不再自己算。
package enum ProductHistoryChart {
    package static func json(
        providerIDRaw: String,
        snapshotsJSON: String,
        rangeRaw: String,
        nowMillis: Int64,
        offset: Int = 0,
        spanLookback: Bool = false
    ) -> String {
        let calendar = ProductClock.calendar()
        let now = ProductClock.date(millis: nowMillis)
        let range = HistoryChartRange(rawValue: rangeRaw) ?? .days30
        let kind = ProviderCatalog.descriptor(id: ProviderID(rawValue: providerIDRaw))?.kind ?? .usage
        let snapshots = JNIJSON.array(snapshotsJSON).compactMap(ProductSnapshotCodec.snapshot(from:))
        let state = HistoryChartMath.make(
            kind: kind,
            snapshots: snapshots,
            range: range,
            now: now,
            calendar: calendar,
            offset: offset,
            spanLookback: spanLookback
        )
        switch state {
        case .spend(let points, let start, let end, let monthly, let isIntervalSpend):
            return JNIJSON.stringify(object(
                kind: "spend",
                points: points,
                start: start,
                end: end,
                monthly: monthly,
                calendar: calendar,
                extra: ["isIntervalSpend": isIntervalSpend]
            ))
        case .balance(let points, let start, let end, let monthly, let inferredStarts):
            return JNIJSON.stringify(object(
                kind: "balance",
                points: points,
                start: start,
                end: end,
                monthly: monthly,
                calendar: calendar,
                extra: ["inferredStarts": inferredStarts.map { Int(ProductClock.millis($0)) }]
            ))
        case .none:
            return JNIJSON.stringify(["kind": "none"])
        }
    }

    private static func object(
        kind: String,
        points: [HistoryChartReading],
        start: Date,
        end: Date,
        monthly: Bool,
        calendar: Calendar,
        extra: [String: Any]
    ) -> [String: Any] {
        var object: [String: Any] = [
            "kind": kind,
            "monthly": monthly,
            "startMillis": Int(ProductClock.millis(start)),
            "endMillis": Int(ProductClock.millis(end)),
            "points": points.map { point in
                [
                    "bucket": Int(ProductClock.millis(point.date)),
                    "amount": point.amount,
                ] as [String: Any]
            },
            // 横轴完整桶序列：缺读数的桶留空位，Kotlin 不再自己铺日历。
            "buckets": HistoryChartMath.periods(
                from: start,
                through: end,
                monthly: monthly,
                calendar: calendar
            ).map { Int(ProductClock.millis($0)) },
            // 纵轴整美元 nice 刻度。刻度**值**在这边算；文字由 Kotlin 过
            // formatUsd 写成显示货币，不再有 "$" 字面量。
            "axisMarks": axisMarks(maxAmount: points.map(\.amount).max() ?? 0),
        ]
        for (key, value) in extra {
            object[key] = value
        }
        return object
    }

    /// 纵轴 nice-step。和 MeterDesign `ChartMoneyScale.marks` 同一套取舍——
    /// Design 不许 import Core，所以那份留在 iOS 渲染层，这份供 Android 渲染层。
    package static func axisMarks(maxAmount: Double) -> [Double] {
        let ceilingValue = max(maxAmount, 0)
        guard ceilingValue > 0 else { return [0, 1] }
        let raw = ceilingValue / 2
        let magnitude = pow(10, (log10(raw)).rounded(.down))
        let residual = raw / magnitude
        let nice: Double
        switch residual {
        case ...1: nice = 1
        case ...2: nice = 2
        case ...5: nice = 5
        default: nice = 10
        }
        var step = nice * magnitude
        var top = step * 2
        if top < ceilingValue {
            step = nextNiceStep(step)
            top = step * 2
        }
        if top < ceilingValue {
            let count = (ceilingValue / step).rounded(.up)
            top = count * step
            var marks: [Double] = []
            var cursor = 0.0
            while cursor <= top + step / 2 {
                marks.append(cursor)
                cursor += step
            }
            return marks
        }
        return [0, step, top]
    }

    private static func nextNiceStep(_ step: Double) -> Double {
        let magnitude = pow(10, (log10(step)).rounded(.down))
        switch step / magnitude {
        case ...1: return 2 * magnitude
        case ...2: return 5 * magnitude
        case ...5: return 10 * magnitude
        default: return 20 * magnitude
        }
    }
}
