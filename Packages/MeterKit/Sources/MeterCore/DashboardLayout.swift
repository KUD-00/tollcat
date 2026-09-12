import Foundation

/// 仪表盘的版式：哪些模块开着、按什么顺序，以及两个模块自己的设置。
///
/// `order` 是**开着的**模块 id（`DashboardModuleID.rawValue`）按用户排的顺序；
/// 不在里面的模块就是关着。空数组 = 还没编辑过，用产品默认。本月合计不进这里，
/// 它永远在最上面。这样一个字段就说清「开没开」和「排第几」，不会出现
/// 「在顺序里但被隐藏」这种要两处对齐的状态。
///
/// 用 String 而不是模块枚举：Core 不认识 Features 的枚举，落盘和迁移包也只认字符串；
/// 新版本加了模块、旧版本读到不认识的 id 直接跳过。
public struct DashboardLayout: Hashable, Sendable {
    public var order: [String]
    /// 「特别关心」钉出来的账号。空 = 模块开着也没东西可显示，自动不出现。
    public var pinnedAccounts: [AccountID]
    /// 「预算线」的月预算，美元。nil = 没设，模块自动不出现。
    public var monthlyBudgetUSD: Decimal?
    /// 钉在侧栏底部的那一块（宽壳才有侧栏）。nil = 不钉。钉了的模块不再出现在主区。
    public var sidebarModule: String?

    public init(
        order: [String] = [],
        pinnedAccounts: [AccountID] = [],
        monthlyBudgetUSD: Decimal? = nil,
        sidebarModule: String? = nil
    ) {
        self.order = Self.normalizedOrder(order)
        self.pinnedAccounts = Self.normalizedAccounts(pinnedAccounts)
        self.monthlyBudgetUSD = monthlyBudgetUSD.flatMap { $0 > 0 ? $0 : nil }
        self.sidebarModule = sidebarModule.flatMap { $0.isEmpty ? nil : $0 }
    }

    public static let `default` = DashboardLayout()

    public var isDefault: Bool { self == .default }

    /// 去重、去空，保留首次出现的位置。
    public static func normalizedOrder(_ ids: [String]) -> [String] {
        var seen: Set<String> = []
        return ids.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    public static func normalizedAccounts(_ ids: [AccountID]) -> [AccountID] {
        var seen: Set<AccountID> = []
        return ids.filter { seen.insert($0).inserted }
    }
}

extension DashboardLayout: Codable {
    /// 落盘 JSON 的形状版本。每个字段都是 `decodeIfPresent`，所以加字段不用 bump；
    /// 只有改了某个字段的**含义或类型**才 bump，并在 `init(from:)` 里按旧版本另解。
    /// 读的时候不认识的版本照样按已知字段解——旧版 App 读到新版落盘时丢的只是它
    /// 不认识的字段，不是整份版式。
    public static let codingVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version = "v"
        case order
        case pinnedAccounts
        case monthlyBudgetUSD
        case sidebarModule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let order = try container.decodeIfPresent([String].self, forKey: .order) ?? []
        let accounts = try container.decodeIfPresent([String].self, forKey: .pinnedAccounts) ?? []
        // 金额写成十进制字符串，别让 Double 把 12.30 存成 12.299999。
        let budget = try container.decodeIfPresent(String.self, forKey: .monthlyBudgetUSD)
            .flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
        self.init(
            order: order,
            pinnedAccounts: accounts.compactMap { UUID(uuidString: $0).map(AccountID.init(rawValue:)) },
            monthlyBudgetUSD: budget,
            sidebarModule: try container.decodeIfPresent(String.self, forKey: .sidebarModule)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.codingVersion, forKey: .version)
        try container.encode(order, forKey: .order)
        try container.encode(pinnedAccounts.map { $0.rawValue.uuidString }, forKey: .pinnedAccounts)
        if let monthlyBudgetUSD {
            try container.encode("\(monthlyBudgetUSD)", forKey: .monthlyBudgetUSD)
        }
        try container.encodeIfPresent(sidebarModule, forKey: .sidebarModule)
    }
}
