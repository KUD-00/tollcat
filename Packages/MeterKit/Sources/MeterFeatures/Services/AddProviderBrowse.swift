import Foundation

/// 添加列表空搜索时列哪一段。打字之后两页都搜全目录。
enum AddProviderBrowse: Equatable, Sendable {
    /// 常见服务：市占档 1、2，刨去只支持读数信箱的，按品类分组。
    case featured
    /// 更多服务：剩下的全部，按品类分组。
    case more
}
