import Foundation

/// 模块在页面上的分区。第一块永远是本月合计（英雄区），其余按版式顺序排；
/// 手机上相邻的「需要注意」模块并成同一节，卡上各自成卡。
public enum DashboardModuleRegion {
    public static func attentionIDs(from visible: [DashboardModuleID]) -> [DashboardModuleID] {
        visible.filter(\.isAttention)
    }

    public static func hasComposition(in visible: [DashboardModuleID]) -> Bool {
        visible.contains(.composition)
    }

    /// 英雄区之外、按顺序排的模块（构成也在英雄区里，由 CatStage 画）。
    public static func bodyIDs(from visible: [DashboardModuleID]) -> [DashboardModuleID] {
        visible.filter { $0 != .monthToDate && $0 != .composition }
    }

    /// 手机列表的分节：相邻的「需要注意」并成一节（标题「需要注意」），其他模块各自一节。
    public struct Section: Identifiable, Hashable {
        public var ids: [DashboardModuleID]

        public init(ids: [DashboardModuleID]) {
            self.ids = ids
        }

        public var id: String { ids.map(\.rawValue).joined(separator: "+") }
        public var isAttention: Bool { ids.first?.isAttention ?? false }
    }

    public static func sections(from visible: [DashboardModuleID]) -> [Section] {
        var sections: [Section] = []
        for id in bodyIDs(from: visible) {
            if id.isAttention, let last = sections.last, last.isAttention {
                sections[sections.count - 1].ids.append(id)
            } else {
                sections.append(Section(ids: [id]))
            }
        }
        return sections
    }
}
