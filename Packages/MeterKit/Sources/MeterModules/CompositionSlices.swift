import Foundation
import MeterCore
import MeterDashboard
import MeterDesign
import SwiftUI
import MeterFormat

/// 图例只留前几名；再多的合并成「其他」，避免图例无限变长。
/// 合并规则在 `CompositionSliceBuilder`，这里只按位置配色。
public enum CompositionSlices {
    /// 规则本身在 `CompositionSliceBuilder`（跨端共用）；色板档数必须和它一样多。
    public static var namedLimit: Int { CompositionSliceBuilder.namedLimit }

    public static func make(
        from segments: [CompositionSegment],
        presentation: MoneyPresentation = .usd
    ) -> [CompositionDonut.Slice] {
        CompositionSliceBuilder.make(from: segments, presentation: presentation)
            .enumerated()
            .map { index, slice in
                CompositionDonut.Slice(
                    id: slice.id,
                    color: slice.isOther ? MeterColor.compositionOther : MeterColor.composition(index: index),
                    fraction: slice.fraction,
                    name: slice.displayName,
                    amountText: slice.amountText,
                    spokenAmount: slice.spokenAmount,
                    mergedNames: slice.mergedNames
                )
            }
    }

    public static func spokenOther(from slices: [CompositionDonut.Slice]) -> String? {
        guard let other = slices.first(where: { !$0.mergedNames.isEmpty }) else {
            return nil
        }
        let members = other.mergedNames.joined(separator: "、")
        return String(localized: L("其他包含 \(members)"))
    }
}
