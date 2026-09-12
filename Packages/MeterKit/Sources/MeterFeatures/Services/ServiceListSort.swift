import Foundation

/// 服务页主列表的排序。默认按计费模式，把余额和从量拆开。
///
/// 「计费模式」分的是右侧数字在说什么（从量 / 余额 / 月费 / 额度），
/// 「类别」分的是这家干什么活（AI 推理 / 托管 / 数据库……，标在服务目录里，
/// 和仪表盘「按类别构成」同一套）。两者都是分组，别混成一个词。
enum ServiceListSort: String, CaseIterable, Hashable, Sendable {
    case kind
    case category
    case price

    var title: LocalizedStringResource {
        switch self {
        case .kind: L("计费模式")
        case .category: L("类别")
        case .price: L("价格")
        }
    }
}
