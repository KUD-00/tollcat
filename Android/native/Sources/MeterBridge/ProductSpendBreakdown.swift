import Foundation
import MeterCore
import MeterFormat

/// 详情页「花在哪了」的 JSON。
///
/// **分组规则一条都不在这里**，在 `MeterCore/SpendGrouping`——`MeterFeatures` 的
/// `SpendBreakdownBuilder` 调的是同一个函数。这一层只把值写成字。
///
/// 桥上本来就在送 `lines`，Kotlin 却把这套加法手译了一遍（连 `QuantityFormat`
/// 的位数阈值都抄了，而且 rounding 已经不一样）。出口开在这里之后，
/// 那一端只剩下拼句子和画。
package enum ProductSpendBreakdown {
    package static func json(
        linesJSON: String,
        groupingRaw: String,
        currency: String,
        localeTag: String
    ) -> String {
        let presentation = ProductRates.presentation(currency)
        let mode = SpendGroupingMode(rawValue: groupingRaw) ?? .category
        let lines = ProductSnapshotCodec.spendLines(fromJSONArray: linesJSON)
        let groups = SpendGrouping.make(lines: lines, mode: mode)
        guard !groups.isEmpty else {
            return JNIJSON.stringify([
                "jniSchema": JNISchema.version,
                "empty": true,
            ])
        }

        var object: [String: Any] = [
            "jniSchema": JNISchema.version,
            "empty": false,
            "mode": groups.mode.rawValue,
            "supportsScope": groups.supportsScope,
            "totalText": groups.total.formatted(using: presentation),
            "itemCount": groups.itemCount,
            "groups": groups.buckets.map { group($0, presentation: presentation) },
        ]
        if let listTotal = groups.listTotal, let saved = groups.savedTotal {
            object["listTotalText"] = listTotal.formatted(using: presentation)
            object["savedText"] = saved.formatted(using: presentation)
        }
        _ = localeTag
        return JNIJSON.stringify(object)
    }

    private static func group(
        _ bucket: SpendGroupedBucket,
        presentation: MoneyPresentation
    ) -> [String: Any] {
        var object: [String: Any] = [
            "id": bucket.id,
            // 「其他」那一组的标题由 Kotlin 填——那两个字要本地化，不在桥上写死。
            "title": bucket.title,
            "isOther": bucket.isOther,
            "amountText": bucket.amount.formatted(using: presentation),
            "fraction": bucket.fraction,
            "isZeroBilled": bucket.isZeroBilled,
            "items": bucket.items.map { item($0, presentation: presentation) },
        ]
        if let share = shareCaption(bucket.share) { object["shareCaption"] = share }
        if let detail = quantityCaption(bucket.quantity, unit: bucket.unit) {
            object["detailCaption"] = detail
        }
        if let discount = bucket.discount {
            object["discountText"] = discount.formatted(using: presentation)
        }
        if let note = bucket.allowanceNote { object["allowanceNote"] = note }
        return object
    }

    private static func item(
        _ item: SpendGroupedItem,
        presentation: MoneyPresentation
    ) -> [String: Any] {
        let line = item.line
        var object: [String: Any] = [
            "id": item.id,
            "title": item.title,
            "amountText": line.amountUSD.formatted(using: presentation),
        ]
        let detail = [quantityCaption(line.quantity, unit: line.unit), line.allowanceNote]
            .compactMap { $0 }
            .joined(separator: " · ")
        if !detail.isEmpty { object["detailCaption"] = detail }
        if line.discountUSD != nil, let list = line.listUSD {
            object["listText"] = list.formatted(using: presentation)
        }
        return object
    }

    /// 纯数字 + %，不进文案表。
    private static func shareCaption(_ share: SpendShare) -> String? {
        switch share {
        case .none: nil
        case .belowOnePercent: "<1%"
        case let .percent(value): "\(value)%"
        }
    }

    private static func quantityCaption(_ quantity: Decimal?, unit: String?) -> String? {
        guard let quantity, let unit, !unit.isEmpty else { return nil }
        return "\(QuantityFormat.string(quantity)) \(unit)"
    }
}
