import Foundation
import MeterCore
import MeterProviders

enum AddProviderSearch {
    static func descriptors(in catalog: [ProviderDescriptor], query: String) -> [ProviderDescriptor] {
        catalog.filter { $0.matchesSearchQuery(query) }
    }

    static func orderedCatalog() -> [ProviderDescriptor] {
        ServiceListOrder.ids.compactMap { ProviderCatalog.descriptor(id: $0) }
    }

    /// 全目录匹配（已加进来的除外）。搜索词空时每一家都算命中。
    static func matchingDescriptors(
        query: String,
        excluding memberIDs: Set<ProviderID> = []
    ) -> [ProviderDescriptor] {
        descriptors(in: orderedCatalog(), query: query)
            .filter { !memberIDs.contains($0.id) }
    }

    /// 常见服务：市占档 1、2，刨去只支持读数信箱的。
    static func isFeatured(_ descriptor: ProviderDescriptor) -> Bool {
        descriptor.tier <= .two && !descriptor.supportsInboxIngest
    }

    /// 空搜索按浏览范围切；一打字就搜全目录，档 3、4 和只走读数信箱的也能命中。
    static func visibleDescriptors(
        query: String,
        excluding memberIDs: Set<ProviderID> = [],
        browse: AddProviderBrowse
    ) -> [ProviderDescriptor] {
        let matches = matchingDescriptors(query: query, excluding: memberIDs)
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return matches
        }
        switch browse {
        case .featured:
            return matches.filter(isFeatured)
        case .more:
            return matches.filter { !isFeatured($0) }
        }
    }

    static func sections(from descriptors: [ProviderDescriptor]) -> [AddProviderCatalogSection] {
        guard !descriptors.isEmpty else { return [] }
        var buckets: [ProviderCategory: [ProviderDescriptor]] = [:]
        for descriptor in descriptors {
            buckets[descriptor.category, default: []].append(descriptor)
        }
        for category in buckets.keys {
            buckets[category]?.sort {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
        }
        let categories = ProviderCategory.allCases.filter { buckets[$0] != nil }
        let showTitles = categories.count > 1
        return categories.map { category in
            AddProviderCatalogSection(
                category: showTitles ? category : nil,
                descriptors: buckets[category] ?? []
            )
        }
    }

    static func showsMoreRow(
        query: String,
        excluding memberIDs: Set<ProviderID> = []
    ) -> Bool {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return matchingDescriptors(query: "", excluding: memberIDs)
            .contains { !isFeatured($0) }
    }

    static func matchesManualRow(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return true }
        return String(localized: L("手动订阅")).localizedStandardContains(needle)
    }

    static func showsEmptySearch(
        query: String,
        excluding memberIDs: Set<ProviderID> = [],
        browse: AddProviderBrowse = .featured
    ) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return false }
        return visibleDescriptors(query: query, excluding: memberIDs, browse: browse).isEmpty
            && !matchesManualRow(query)
    }

    /// 兼容旧测试名：空搜索走常见服务。
    static func filteredDescriptors(
        query: String,
        excluding memberIDs: Set<ProviderID> = []
    ) -> [ProviderDescriptor] {
        visibleDescriptors(query: query, excluding: memberIDs, browse: .featured)
    }
}
