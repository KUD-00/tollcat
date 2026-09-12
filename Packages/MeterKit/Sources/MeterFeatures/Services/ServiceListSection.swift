import MeterCore

/// 服务页主列表的一组。按计费模式时一组一种钱，按类别时一组一类活；
/// 按价格时只有一组、没有标题。
struct ServiceListSection: Equatable, Identifiable, Sendable {
    var id: String
    var kind: ProviderKind?
    var category: ProviderCategory?
    var title: String?
    var rows: [ServiceRowItem]
}
