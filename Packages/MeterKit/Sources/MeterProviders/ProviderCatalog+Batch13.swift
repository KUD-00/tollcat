import Foundation
import MeterCore

extension ProviderCatalog {
    public static let voltagepark = ProviderDescriptor(
        id: .voltagepark,
        displayName: "Voltage Park",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "GPU 云算力新秀，规模仍远小于 CoreWeave/Vast。",
        colorKey: "voltagepark",
        billingURL: URL(string: "https://cloud.voltagepark.com")!,
        credentialSetupURL: URL(string: "https://docs.voltagepark.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["voltage park", "voltagepark", "tensordock", "gpu"]
    )

    public static let smsc = ProviderDescriptor(
        id: .smsc,
        displayName: "SMSC.ru",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "欧洲短信网关细分里的区域选手。",
        colorKey: "smsc",
        billingURL: URL(string: "https://smsc.ru")!,
        credentialSetupURL: URL(string: "https://smsc.ru/passwords/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["smsc.ru", "sms центр", "смс"]
    )

    public static let openprovider = ProviderDescriptor(
        id: .openprovider,
        displayName: "Openprovider",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "域名批发商细分里的欧洲选手。",
        colorKey: "openprovider",
        billingURL: URL(string: "https://rcp.openprovider.eu")!,
        credentialSetupURL: URL(string: "https://docs.openprovider.com/doc#tag/InvoiceService")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["openprovider", "domains", "reseller"]
    )

    public static let realtimeregister = ProviderDescriptor(
        id: .realtimeregister,
        displayName: "Realtime Register",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "域名注册 API 细分里的欧洲选手。",
        colorKey: "realtimeregister",
        billingURL: URL(string: "https://dm.realtimeregister.com")!,
        credentialSetupURL: URL(string: "https://dm.realtimeregister.com/docs/api/transactions/list")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["realtime register", "yoursrs", "financialtransactions", "cents", "EUR"]
    )

    public static let stackit = ProviderDescriptor(
        id: .stackit,
        displayName: "STACKIT",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "德国主权云/公共云挑战者，仍远小于 Hyperscaler。",
        colorKey: "stackit",
        billingURL: URL(string: "https://portal.stackit.cloud")!,
        credentialSetupURL: URL(string: "https://docs.stackit.cloud/platform/cost-and-billing/how-tos/retrieve-stackit-invoices/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["stackit", "schwarz", "deutsche telekom cloud"]
    )

    public static let unleash = ProviderDescriptor(
        id: .unleash,
        displayName: "Unleash",
        kind: .usage,
        category: .devTools,
        tier: .two,
        tierReason: "开源功能开关的强挑战者，与 LaunchDarkly 分流。",
        colorKey: "unleash",
        billingURL: URL(string: "https://www.getunleash.io")!,
        credentialSetupURL: URL(string: "https://docs.getunleash.io/api/get-detailed-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["unleash", "feature flags", "invoices/list", "totalAmount", "enterprise"]
    )

    public static let rediscloud = ProviderDescriptor(
        id: .rediscloud,
        displayName: "Redis Cloud",
        kind: .usage,
        category: .database,
        tier: .one,
        tierReason: "托管 Redis 的品类龙头，企业采购默认选项。",
        colorKey: "rediscloud",
        billingURL: URL(string: "https://app.redislabs.com/")!,
        credentialSetupURL: URL(string: "https://redis.io/docs/latest/operate/rc/api/examples/generate-cost-report/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 3,
        accessStatus: .pendingVerification,
        searchKeywords: ["redis cloud", "redis labs", "cost-report", "FOCUS", "BilledCost"]
    )

    public static let pdfshift = ProviderDescriptor(
        id: .pdfshift,
        displayName: "PDFShift",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "HTML 转 PDF API 细分里的小型选手。",
        colorKey: "pdfshift",
        billingURL: URL(string: "https://app.pdfshift.io/dashboard/")!,
        credentialSetupURL: URL(string: "https://docs.pdfshift.io/api-reference/invoices-list")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["pdfshift", "invoices", "USD", "html to pdf"]
    )

    public static let surrealdb = ProviderDescriptor(
        id: .surrealdb,
        displayName: "SurrealDB Cloud",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "多模型数据库新秀，商业化仍早。",
        colorKey: "surrealdb",
        billingURL: URL(string: "https://app.surrealdb.com")!,
        credentialSetupURL: URL(string: "https://docs.surrealdb.com/cloud/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["surrealdb", "surreal", "cloud"]
    )
}
