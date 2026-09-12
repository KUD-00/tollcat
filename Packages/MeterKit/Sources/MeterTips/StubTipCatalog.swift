import Foundation

/// 罐装的三档。给模拟器截图和 UI 验收用，**一个字节都不出网**。
///
/// 为什么需要它：scheme 上挂的 `TollCat.storekit` 只在 Xcode 启动 App 时注入，
/// `simctl install` + `simctl launch` 装起来的那份拿不到，真的
/// `Product.products(for:)` 返回空数组，打赏页只剩「暂时无法连接 App Store」。
/// 审核截图要的正是三档并排的样子，所以只在带 `-stub-tips` 启动参数时装上这一份。
///
/// 金额跟 App Store Connect 上的基准价一样，改价两边一起改。
public struct StubTipCatalog: TipCataloging {
    public init() {}

    public func loadProducts() async throws -> [TipOffering] {
        TipProductID.allCases.map { id in
            TipOffering(
                id: id.rawValue,
                displayName: id.listTitle,
                displayPrice: Self.displayPrice(for: id)
            )
        }
    }

    private static func displayPrice(for id: TipProductID) -> String {
        switch id {
        case .small: "$0.99"
        case .medium: "$4.99"
        case .large: "$9.99"
        }
    }
}
