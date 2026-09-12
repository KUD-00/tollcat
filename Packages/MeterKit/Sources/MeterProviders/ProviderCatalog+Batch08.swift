import Foundation
import MeterCore

extension ProviderCatalog {
    public static let hashicorp = ProviderDescriptor(
        id: .hashicorp,
        displayName: "HashiCorp Cloud",
        kind: .usage,
        category: .dataPipeline,
        tier: .one,
        tierReason: "Vault 仍是密钥与服务身份的事实标准，HCP 是该寡头产品线的托管面并并入 IBM。",
        colorKey: "hashicorp",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "HCP 没有公开账单金额接口。",
        searchKeywords: ["hashicorp", "hcp", "vault", "terraform"]
    )

    public static let appwrite = ProviderDescriptor(
        id: .appwrite,
        displayName: "Appwrite Cloud",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "开源 Firebase 替代仍在扩云与产品面，但开发者规模和融资远落后于 Supabase。",
        colorKey: "appwrite",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["appwrite.io", "baas"]
    )

    public static let stytch = ProviderDescriptor(
        id: .stytch,
        displayName: "Stytch",
        kind: .usage,
        category: .authSecurity,
        tier: .four,
        tierReason: "独立 CIAM 挑战者已被 Twilio 以人才收购收掉。",
        colorKey: "stytch",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["stytch.com", "auth"]
    )

    public static let okta = ProviderDescriptor(
        id: .okta,
        displayName: "Okta",
        kind: .subscription,
        category: .authSecurity,
        tier: .one,
        tierReason: "劳动力身份与微软、Ping 构成访问管理寡头，是独立 IdP 的规模王。",
        colorKey: "okta",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["okta.com", "auth", "sso"]
    )

    public static let chargebee = ProviderDescriptor(
        id: .chargebee,
        displayName: "Chargebee",
        kind: .usage,
        category: .payments,
        tier: .two,
        tierReason: "订阅计费应用的 Gartner 领导者，规模小于 Stripe Billing 但在中大客户侧是强挑战者。",
        colorKey: "chargebee",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口是商户账单产品，不是 Chargebee 自己的订阅账单。",
        searchKeywords: ["chargebee.com", "billing"]
    )

    public static let betterstack = ProviderDescriptor(
        id: .betterstack,
        displayName: "Better Stack",
        kind: .usage,
        category: .observability,
        tier: .two,
        tierReason: "独立可观测性/状态页赛道里增速很快的挑战者，仍小于 Datadog。",
        colorKey: "betterstack",
        billingURL: URL(string: "https://betterstack.com/")!,
        credentialSetupURL: URL(string: "https://betterstack.com/settings/api-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["betterstack", "better stack", "better uptime", "logtail"]
    )

    public static let easypost = ProviderDescriptor(
        id: .easypost,
        displayName: "EasyPost",
        kind: .prepaid,
        category: .other,
        tier: .two,
        tierReason: "美国开发者物流 API 的强挑战者，与 Shippo 等同台。",
        colorKey: "easypost",
        billingURL: URL(string: "https://app.easypost.com/account")!,
        credentialSetupURL: URL(string: "https://docs.easypost.com/docs/authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["easypost", "easy post", "shipping"]
    )

    public static let transloadit = ProviderDescriptor(
        id: .transloadit,
        displayName: "Transloadit",
        kind: .usage,
        category: .media,
        tier: .three,
        tierReason: "媒体文件处理 API 细分市场的小而稳的选手。",
        colorKey: "transloadit",
        billingURL: URL(string: "https://transloadit.com/c/")!,
        credentialSetupURL: URL(string: "https://transloadit.com/docs/api/authentication/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["transloadit", "encoding", "ffmpeg"]
    )

    public static let lemon = ProviderDescriptor(
        id: .lemon,
        displayName: "Lemon Squeezy",
        kind: .usage,
        category: .payments,
        tier: .four,
        tierReason: "已被 Stripe 收购，独立 MoR 品牌正让位于 Stripe Managed Payments。",
        colorKey: "lemon",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "订单只有 total，没有平台抽成字段，不能自己按费率发明。",
        searchKeywords: ["lemonsqueezy", "lemon squeezy", "mor"]
    )

    public static let mapbox = ProviderDescriptor(
        id: .mapbox,
        displayName: "Mapbox",
        kind: .usage,
        category: .networkEdge,
        tier: .two,
        tierReason: "独立地图 SDK 的强挑战者，仍远小于 Google Maps Platform。",
        colorKey: "mapbox",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "官方说明用量数据没有公开 API，控制台只有计量单位。 (evidence: https://docs.mapbox.com/accounts/guides/statistics/)",
        searchKeywords: ["mapbox.com", "maps", "地图"]
    )

    public static let googlemaps = ProviderDescriptor(
        id: .googlemaps,
        displayName: "Google Maps Platform",
        kind: .usage,
        category: .networkEdge,
        tier: .one,
        tierReason: "地图与地点 API 支出的绝对龙头。",
        colorKey: "googlemaps",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有简单的只读账单金额 HTTP；金额要走 Cloud Billing BigQuery 导出。",
        searchKeywords: ["google maps", "maps platform", "gmp", "地图"]
    )

    public static let docusign = ProviderDescriptor(
        id: .docusign,
        displayName: "DocuSign",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "电子签名市场近乎垄断，企业采购默认选项。",
        colorKey: "docusign",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "billing_charges 只给单价和用量数量，没有已发生金额合计。",
        searchKeywords: ["docusign.com", "esign", "电子签名"]
    )

    public static let typeform = ProviderDescriptor(
        id: .typeform,
        displayName: "Typeform",
        kind: .subscription,
        category: .analytics,
        tier: .two,
        tierReason: "互动表单/调研的强挑战者，与 Google Forms 等分流。",
        colorKey: "typeform",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有表单与回复，没有账单金额。",
        searchKeywords: ["typeform.com", "forms", "表单"]
    )

    public static let kit = ProviderDescriptor(
        id: .kit,
        displayName: "Kit",
        kind: .subscription,
        category: .messaging,
        tier: .three,
        tierReason: "创作者邮件营销细分里的中小型选手。",
        colorKey: "kit",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账户接口只有套餐元数据与额度，没有账单金额。",
        searchKeywords: ["kit.com", "convertkit", "email", "newsletter"]
    )

    public static let api2pdf = ProviderDescriptor(
        id: .api2pdf,
        displayName: "Api2Pdf",
        kind: .prepaid,
        category: .other,
        tier: .three,
        tierReason: "HTML/URL 转 PDF API 细分里的小型选手。",
        colorKey: "api2pdf",
        billingURL: URL(string: "https://portal.api2pdf.com")!,
        credentialSetupURL: URL(string: "https://www.api2pdf.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["api2pdf", "pdf", "html to pdf"]
    )

    public static let hetrixtools = ProviderDescriptor(
        id: .hetrixtools,
        displayName: "HetrixTools",
        kind: .prepaid,
        category: .observability,
        tier: .three,
        tierReason: "服务器与黑名单监控细分里的小型选手。",
        colorKey: "hetrixtools",
        billingURL: URL(string: "https://hetrixtools.com/dashboard/")!,
        credentialSetupURL: URL(string: "https://hetrixtools.com/dashboard/account/api/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["hetrix", "hetrixtools", "uptime", "blacklist"]
    )
}
