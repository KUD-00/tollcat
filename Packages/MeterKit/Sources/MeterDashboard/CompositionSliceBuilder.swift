import Foundation
import MeterCore
import MeterFormat

/// 构成段 → 图例段。「前几名 + 其他」这条规则**只在这里写一份**：
/// iOS 的构成模块 / 详情 / 分享卡、桥给 Android / Windows 的 JSON 都从这里取。
public enum CompositionSliceBuilder {
    /// 前 N 名各占一色，之后并成「其他」。iOS 色板（`MeterColor.compositionStops`）
    /// 和 Android 色阶都按这个数配，测试会核对两边一样多。
    public static let namedLimit = 5
    public static let otherID = "other"

    public static func make(
        from segments: [CompositionSegment],
        presentation: MoneyPresentation
    ) -> [CompositionSlice] {
        guard segments.count > namedLimit else {
            return segments.map { slice($0, presentation: presentation) }
        }
        let named = segments.prefix(namedLimit).map { slice($0, presentation: presentation) }
        let rest = segments.dropFirst(namedLimit)
        // 加的是 `Money`，不是写好的字：换算只在最后写成字时发生一次。
        let amount = rest.reduce(Money.zero) { $0 + $1.amount }
        let other = CompositionSlice(
            id: otherID,
            displayName: L("其他"),
            colorKey: otherID,
            amount: amount,
            amountText: amount.formatted(using: presentation),
            spokenAmount: SpokenMoney.label(for: amount, presentation: presentation),
            fraction: rest.reduce(0) { $0 + $1.fraction },
            percent: min(100, rest.reduce(0) { $0 + $1.percent }),
            isOther: true,
            mergedNames: rest.map(\.displayName)
        )
        return named + [other]
    }

    private static func slice(_ segment: CompositionSegment, presentation: MoneyPresentation) -> CompositionSlice {
        CompositionSlice(
            id: segment.id,
            accountID: segment.accountID,
            providerID: segment.providerID,
            displayName: segment.displayName,
            colorKey: segment.colorKey,
            amount: segment.amount,
            amountText: segment.amount.formatted(using: presentation),
            spokenAmount: SpokenMoney.label(for: segment.amount, presentation: presentation),
            fraction: segment.fraction,
            percent: segment.percent
        )
    }
}
