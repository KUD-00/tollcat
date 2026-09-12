import Foundation
import MeterCore
import MeterFormat

/// `[SpendLine]` → 一屏可以直接画的内容。**这一层只写字。**
///
/// 分到哪一组、谁排前面、超出几组折成「其他」、占比怎么算，全在
/// `MeterCore/SpendGrouping`——Android 桥要同一份分组规则，而它链不了 Features。
/// 那份规则以前在这里，于是 Kotlin 手译了一版；两份都对是巧合。
///
/// 各家的差别在下面那层已经消化完了：Cloudflare 送来的是产品线 + 服务，
/// GitHub 送来的是 product + sku + 仓库，走的都是同一份代码。界面长得不一样，
/// 是因为 `scope` 有没有值、`listUSD` 有没有值——是数据的差别，不是分支。
enum SpendBreakdownBuilder {
    static func make(
        lines: [SpendLine]?,
        grouping: SpendBreakdownGrouping,
        presentation: MoneyPresentation
    ) -> SpendBreakdownContent {
        let groups = SpendGrouping.make(lines: lines, mode: grouping)
        guard !groups.isEmpty else { return .empty }

        return SpendBreakdownContent(
            groups: groups.buckets.map { group($0, presentation: presentation) },
            supportsScopeGrouping: groups.supportsScope,
            totalCaption: groups.total.formatted(using: presentation),
            discountCaption: discountCaption(groups, presentation: presentation),
            itemCount: groups.itemCount,
            spokenSummary: String(
                localized: L("明细合计 \(SpokenMoney.label(for: groups.total, presentation: presentation))")
            )
        )
    }

    private static func group(
        _ bucket: SpendGroupedBucket,
        presentation: MoneyPresentation
    ) -> SpendBreakdownGroup {
        let title = bucket.isOther ? String(localized: L("其他")) : bucket.title
        return SpendBreakdownGroup(
            id: bucket.id,
            title: title,
            amountCaption: bucket.amount.formatted(using: presentation),
            fraction: bucket.fraction,
            shareCaption: shareCaption(bucket.share),
            detailCaption: quantityCaption(bucket.quantity, unit: bucket.unit),
            allowanceCaption: bucket.discount.map { saved in
                String(localized: L("额度抵扣 \(saved.formatted(using: presentation))"))
            } ?? bucket.allowanceNote,
            isZeroBilled: bucket.isZeroBilled,
            items: bucket.items.map { item($0, presentation: presentation) },
            spokenLabel: String(
                localized: L("\(title)，\(SpokenMoney.label(for: bucket.amount, presentation: presentation))")
            )
        )
    }

    private static func item(
        _ item: SpendGroupedItem,
        presentation: MoneyPresentation
    ) -> SpendBreakdownItem {
        let line = item.line
        return SpendBreakdownItem(
            id: item.id,
            title: item.title,
            amountCaption: line.amountUSD.formatted(using: presentation),
            detailCaption: [quantityCaption(line.quantity, unit: line.unit), line.allowanceNote]
                .compactMap { $0 }
                .joined(separator: " · ")
                .nilWhenEmpty,
            listCaption: line.discountUSD.map { _ in
                String(localized: L("原价 \(line.listUSD?.formatted(using: presentation) ?? "")"))
            },
            spokenLabel: String(
                localized: L("\(item.title)，\(SpokenMoney.label(for: line.amountUSD, presentation: presentation))")
            )
        )
    }

    /// 纯数字 + %，不进 String Catalog——和 `CompositionDetailView.percentText` 同一处理。
    private static func shareCaption(_ share: SpendShare) -> String? {
        switch share {
        case .none: nil
        case .belowOnePercent: "<1%"
        case let .percent(value): "\(value)%"
        }
    }

    private static func discountCaption(
        _ groups: SpendGroups,
        presentation: MoneyPresentation
    ) -> String? {
        guard let listTotal = groups.listTotal, let saved = groups.savedTotal else { return nil }
        return String(
            localized: L(
                "原价 \(listTotal.formatted(using: presentation))，额度抵扣 \(saved.formatted(using: presentation))"
            )
        )
    }

    /// 用量原样写，单位不翻译。数量本身按厂商给的精度收敛——
    /// `0.46822993099999999 GigabyteHours` 不是给人看的。
    private static func quantityCaption(_ quantity: Decimal?, unit: String?) -> String? {
        guard let quantity, let unit, !unit.isEmpty else { return nil }
        return "\(QuantityFormat.string(quantity)) \(unit)"
    }
}

private extension String {
    var nilWhenEmpty: String? { isEmpty ? nil : self }
}
