import MeterCore

enum ServicesRoute: Hashable {
    case add
    /// 添加列表里「更多服务」那一页：常见服务之外剩下的全部。搜索仍走全目录。
    case addMore
    case subscription
    case detail(ProviderID)
    /// 不再花钱、但过去花过的那些。入口和「添加服务」同一节。
    case past
}
