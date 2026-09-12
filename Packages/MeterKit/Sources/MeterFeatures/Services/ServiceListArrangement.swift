import MeterCore

/// 把已接入的行收成服务页要渲染的分组。
///
/// 计费模式的顺序跟「右侧数字在说什么」走：已经花了的（从量、月费加超额）在前，
/// 还剩多少（预充值）随后，月费和额度最后。不要按加入顺序把余额和从量掺在一起。
///
/// 类别的顺序跟目录里的声明序走（AI 推理开头、其他收尾），不按金额排——
/// 刷新一次就重排组序会让人找不着刚看过的那一行，而免费额度行的数字是百分比，
/// 掺进合计也不干净。
enum ServiceListArrangement {
    static let kindOrder: [ProviderKind] = [
        .usage, .planAndUsage, .prepaid, .subscription, .freeTier,
    ]

    static let categoryOrder: [ProviderCategory] = ProviderCategory.allCases

    static func sections(
        from rows: [ServiceRowItem],
        sort: ServiceListSort
    ) -> [ServiceListSection] {
        switch sort {
        case .price:
            return flat(rows.sorted(by: priceBefore))
        case .kind:
            return groupedByKind(rows)
        case .category:
            return groupedByCategory(rows)
        }
    }

    private static func flat(_ rows: [ServiceRowItem]) -> [ServiceListSection] {
        guard !rows.isEmpty else { return [] }
        return [
            ServiceListSection(id: "flat", kind: nil, category: nil, title: nil, rows: rows),
        ]
    }

    private static func groupedByKind(_ rows: [ServiceRowItem]) -> [ServiceListSection] {
        guard !rows.isEmpty else { return [] }
        var buckets: [ProviderKind: [ServiceRowItem]] = [:]
        for row in rows {
            buckets[row.kind, default: []].append(row)
        }
        let kinds = kindOrder.filter { buckets[$0] != nil }
        let showTitles = kinds.count > 1
        return kinds.map { kind in
            ServiceListSection(
                id: kind.rawValue,
                kind: kind,
                category: nil,
                title: showTitles ? ProviderListingCopy.kindTitle(kind) : nil,
                rows: buckets[kind] ?? []
            )
        }
    }

    private static func groupedByCategory(_ rows: [ServiceRowItem]) -> [ServiceListSection] {
        guard !rows.isEmpty else { return [] }
        var buckets: [ProviderCategory: [ServiceRowItem]] = [:]
        for row in rows {
            buckets[row.category, default: []].append(row)
        }
        let categories = categoryOrder.filter { buckets[$0] != nil }
        let showTitles = categories.count > 1
        return categories.map { category in
            ServiceListSection(
                id: category.rawValue,
                kind: nil,
                category: category,
                title: showTitles ? String(localized: category.title) : nil,
                rows: buckets[category] ?? []
            )
        }
    }

    private static func priceBefore(_ lhs: ServiceRowItem, _ rhs: ServiceRowItem) -> Bool {
        if lhs.amountValue != rhs.amountValue {
            return lhs.amountValue > rhs.amountValue
        }
        return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
    }
}
