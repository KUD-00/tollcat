import Foundation
import MeterCore

/// 编译进 App 的静态元数据。
///
/// **安全红线（SPEC 第 07 节 / 12.5 节）：** `billingURL`、`credentialSetupURL`
/// 以及任何 API 端点都必须写死在本模块，**两个 URL 都不进 catalog**。
/// 远程可改的跳转地址等于钓鱼登录页。不要图方便把这类字段挪到 catalog。
///
/// - `billingURL`：官网账单页，详情「去官网处理」跳这里。不接入的家可以没有。
/// - `credentialSetupURL`：直达创建 token 的那一页，向导步骤里的行内链接默认跳这里。不接入的家可以没有。
/// - `guideURLs`：教程里其它官方页（比如怎么找 Account ID），键和 catalog 的
///   `linkTarget` 对齐。**仍然编译进 App，不进 catalog。**
public struct ProviderDescriptor: Hashable, Sendable {
    public var id: ProviderID
    public var displayName: String
    public var kind: ProviderKind
    /// 归哪一类花钱，仪表盘「按类别构成」按它收段。
    public var category: ProviderCategory
    /// 所属品类里的市占位置。
    public var tier: ProviderTier
    /// 为什么标这个档。给人读的，不进 String Catalog。
    public var tierReason: String
    /// 传给 `MeterColor.provider(_:)` 的 key。本模块不 import MeterDesign。
    public var colorKey: String
    public var billingURL: URL?
    public var credentialSetupURL: URL?
    /// 教程额外深链。空键不要。
    public var guideURLs: [String: URL]
    public var costsMoneyToRefresh: Bool
    public var supportsDailyGranularity: Bool
    /// 这家能不能走「读数信箱」——用户自己取数后投递进来。
    ///
    /// **只给官方根本没有账单接口的那几家开。** 能用 API key 正常取数的家一律 false：
    /// 信箱那条路拿不到可对账的数字，给用户开这个口子等于把他从好路推到坏路上。
    /// 界面上对 false 的家不出现任何入口和指引。
    public var supportsInboxIngest: Bool
    /// 接入和「拉取更多历史」往回看几个月。0 表示没有历史窗口，按钮也不出现。
    public var historyLookbackMonths: Int
    /// 两次成功刷新之间的最短间隔。0 表示不另限（自动刷新仍走全局保鲜期，手动下拉照刷）。
    ///
    /// 给「对方按天限流、或数据按天才更新」的家用，见 `RefreshCadence`。
    public var minimumRefreshInterval: TimeInterval
    public var accessStatus: ProviderAccessStatus
    /// 不接入的理由。只给 `.declined` 写；产品列表滤掉，不进 String Catalog。
    public var declineReason: String?
    /// 搜索别名，不是展示文案。
    ///
    /// 同一数组里同时放中英别名，这样中文环境搜 `claude`、英文环境搜「克劳德」
    /// 都能命中。这些词不进 String Catalog、不参与翻译。
    public var searchKeywords: [String]

    public init(
        id: ProviderID,
        displayName: String,
        kind: ProviderKind,
        category: ProviderCategory = .other,
        tier: ProviderTier,
        tierReason: String,
        colorKey: String,
        billingURL: URL? = nil,
        credentialSetupURL: URL? = nil,
        costsMoneyToRefresh: Bool,
        supportsDailyGranularity: Bool,
        supportsInboxIngest: Bool = false,
        historyLookbackMonths: Int = 0,
        minimumRefreshInterval: TimeInterval = 0,
        accessStatus: ProviderAccessStatus,
        declineReason: String? = nil,
        searchKeywords: [String] = [],
        guideURLs: [String: URL] = [:]
    ) {
        self.id = id
        self.displayName = displayName
        self.kind = kind
        self.category = category
        self.tier = tier
        self.tierReason = tierReason
        self.colorKey = colorKey
        self.billingURL = billingURL
        self.credentialSetupURL = credentialSetupURL
        self.costsMoneyToRefresh = costsMoneyToRefresh
        self.supportsDailyGranularity = supportsDailyGranularity
        self.supportsInboxIngest = supportsInboxIngest
        self.historyLookbackMonths = max(0, historyLookbackMonths)
        self.minimumRefreshInterval = max(0, minimumRefreshInterval)
        self.accessStatus = accessStatus
        self.declineReason = declineReason
        self.searchKeywords = searchKeywords
        self.guideURLs = guideURLs
    }

    /// 产品列表（添加、落地页）只列这些。不接入的家仍在 `ProviderCatalog.all` 里。
    public var isOffered: Bool { accessStatus != .declined }

    /// 向导步骤的行内链接。`target` 对不上就回落到创建 token 那页。
    public func setupLinkURL(target: String = "") -> URL? {
        if !target.isEmpty, let url = guideURLs[target] {
            return url
        }
        return credentialSetupURL
    }

    /// 显示名 + 关键词，忽略大小写与变音符号。
    public func matchesSearchQuery(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        if displayName.localizedStandardContains(needle) {
            return true
        }
        return searchKeywords.contains { $0.localizedStandardContains(needle) }
    }
}
