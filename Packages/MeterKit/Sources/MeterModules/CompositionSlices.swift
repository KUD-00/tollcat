import Foundation
import MeterCore
import MeterDesign
import SwiftUI
import MeterFormat

/// 图例只留前几名；再多的合并成「其他」，避免图例无限变长。
/// 「几名」由构成色板的档数决定（`MeterColor.compositionNamedLimit`）。
public enum CompositionSlices {
    public static var namedLimit: Int { MeterColor.compositionNamedLimit }

    public static func make(
        from segments: [CompositionSegment],
        presentation: MoneyPresentation = .usd
    ) -> [CompositionDonut.Slice] {
        guard segments.count > namedLimit else {
            return segments.enumerated().map { index, segment in
                namedSlice(segment, color: MeterColor.composition(index: index), presentation: presentation)
            }
        }

        let named = Array(segments.prefix(namedLimit))
        let rest = Array(segments.dropFirst(namedLimit))
        var slices = named.enumerated().map { index, segment in
            namedSlice(segment, color: MeterColor.composition(index: index), presentation: presentation)
        }

        let amount = rest.reduce(Money.zero) { $0 + $1.amount }
        let fraction = rest.reduce(0) { $0 + $1.fraction }
        slices.append(
            CompositionDonut.Slice(
                id: "other",
                color: MeterColor.compositionOther,
                fraction: fraction,
                name: String(localized: L("其他")),
                amountText: amount.formatted(using: presentation),
                spokenAmount: SpokenMoney.label(for: amount, presentation: presentation),
                mergedNames: rest.map(\.displayName)
            )
        )
        return slices
    }

    public static func spokenOther(from slices: [CompositionDonut.Slice]) -> String? {
        guard let other = slices.first(where: { !$0.mergedNames.isEmpty }) else {
            return nil
        }
        let members = other.mergedNames.joined(separator: "、")
        return String(localized: L("其他包含 \(members)"))
    }

    private static func namedSlice(
        _ segment: CompositionSegment,
        color: Color,
        presentation: MoneyPresentation
    ) -> CompositionDonut.Slice {
        CompositionDonut.Slice(
            id: segment.id,
            color: color,
            fraction: segment.fraction,
            name: segment.displayName,
            amountText: segment.amount.formatted(using: presentation),
            spokenAmount: SpokenMoney.label(for: segment.amount, presentation: presentation)
        )
    }
}
