import Foundation
import MeterCore

public enum CategoriesBuilder {
    /// 加法在 `MeterCore/CategoryShares`（Android 桥要同一份），这里只写字。
    public static func make(
        composition: CompositionModuleContent?,
        presentation: MoneyPresentation
    ) -> CategoriesModuleContent? {
        guard let segments = composition?.segments, !segments.isEmpty else { return nil }
        let shares = CategoryShares.make(
            from: segments.map { segment in
                CategoryShareMember(
                    providerID: segment.providerID,
                    displayName: segment.displayName,
                    colorKey: segment.colorKey,
                    amount: segment.amount
                )
            }
        )
        guard !shares.isEmpty else { return nil }
        let slices = shares.map { share in
            CategorySlice(
                category: share.category,
                amountText: share.amount.formatted(using: presentation),
                fraction: share.fraction,
                percent: share.percent,
                colorKey: share.colorKey,
                memberNames: share.memberNames
            )
        }
        let spoken = slices.map { "\(String(localized: $0.title)) \($0.percent)%" }.joined(separator: "，")
        return CategoriesModuleContent(slices: slices, spokenLabel: spoken)
    }
}
