import Foundation
import MeterCore

/// 「按类别构成」：几十家收成几段。类别标在服务目录里，这里只做加法。
public struct CategoriesModuleContent: Equatable, Sendable {
    public var slices: [CategorySlice]
    public var spokenLabel: String

    public init(slices: [CategorySlice], spokenLabel: String) {
        self.slices = slices
        self.spokenLabel = spokenLabel
    }

    public var animationSignature: [Double] { slices.map(\.fraction) }
}

public struct CategorySlice: Identifiable, Equatable, Sendable {
    public var category: ProviderCategory
    public var amountText: String
    public var fraction: Double
    public var percent: Int
    /// 段里花最多那家的品牌色。不另造一套调色板。
    public var colorKey: String
    /// 段里有哪几家，无障碍标签和图例的副标题用。
    public var memberNames: [String]

    public init(
        category: ProviderCategory,
        amountText: String,
        fraction: Double,
        percent: Int,
        colorKey: String,
        memberNames: [String]
    ) {
        self.category = category
        self.amountText = amountText
        self.fraction = fraction
        self.percent = percent
        self.colorKey = colorKey
        self.memberNames = memberNames
    }

    public var id: ProviderCategory { category }

    public var title: LocalizedStringResource { category.title }
}

public extension ProviderCategory {
    public var title: LocalizedStringResource {
        switch self {
        case .aiInference: L("AI 推理")
        case .gpuCompute: L("GPU 算力")
        case .hosting: L("托管")
        case .database: L("数据库")
        case .search: L("搜索")
        case .networkEdge: L("网络与边缘")
        case .storage: L("存储")
        case .media: L("媒体")
        case .devTools: L("开发平台")
        case .ciCd: L("CI 与测试")
        case .observability: L("监控")
        case .authSecurity: L("身份与安全")
        case .payments: L("收款")
        case .messaging: L("通讯")
        case .collaboration: L("协作")
        case .cms: L("内容与建站")
        case .analytics: L("分析")
        case .automation: L("自动化")
        case .dataPipeline: L("数据管道")
        case .other: L("其他")
        }
    }
}
