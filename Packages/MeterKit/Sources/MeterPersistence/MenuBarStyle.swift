import Foundation

/// Mac 菜单栏常驻那一小块露什么。默认只露猫：金额点开才看得到，
/// 旁人瞄一眼屏幕看不出这个月花了多少。只有 Mac 壳读它；iPhone / iPad 不展示。
public enum MenuBarStyle: String, CaseIterable, Sendable, Codable, Equatable {
    /// 只有一只猫，表情跟仪表盘同步。
    case cat
    /// 猫在前、本月金额在后。
    case catAndAmount
    /// 只有本月金额，没有数据时写 TollCat。
    case amount

    public static let `default`: MenuBarStyle = .cat
}
