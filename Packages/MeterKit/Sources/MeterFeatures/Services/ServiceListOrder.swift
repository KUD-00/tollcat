import MeterCore
import MeterProviders

/// 添加列表和服务页共用的顺序：产品目录里每一家，按显示名字母序。不接入的家不在这里。
enum ServiceListOrder {
    static var ids: [ProviderID] {
        ProviderCatalog.offered
            .sorted {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            .map(\.id)
    }
}
