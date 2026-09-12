import Foundation
import MeterCore

extension ProviderCatalog {
    public static let hostens = ProviderDescriptor(
        id: .hostens,
        displayName: "Hostens",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "东欧/北欧区域 VPS 主机市场的中小型选手，体量远小于 OVH、Hetzner。",
        colorKey: "hostens",
        billingURL: URL(string: "https://billing.hostens.com")!,
        credentialSetupURL: URL(string: "https://billing.hostens.com/userapi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["hostens", "invoice", "acc_balance", "vps"]
    )

    public static let binarylane = ProviderDescriptor(
        id: .binarylane,
        displayName: "BinaryLane",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "澳大利亚本地 VPS 主机的区域选手，规模小于亚太主流公有云。",
        colorKey: "binarylane",
        billingURL: URL(string: "https://www.binarylane.com.au")!,
        credentialSetupURL: URL(string: "https://api.binarylane.com.au/reference/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["binarylane", "binary lane", "unbilled_total", "AUD", "australia"]
    )

    public static let tierpoint = ProviderDescriptor(
        id: .tierpoint,
        displayName: "TierPoint Metallic",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "美国托管与 Metallic 消费云细分里的中型玩家，不及超大规模云。",
        colorKey: "tierpoint",
        billingURL: URL(string: "https://www.tierpoint.com")!,
        credentialSetupURL: URL(string: "https://api.tierpoint.com/api/v1/usage/v3/api-docs")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["tierpoint", "metallic", "usageReport", "consumption", "mrr"]
    )

    public static let postman = ProviderDescriptor(
        id: .postman,
        displayName: "Postman",
        kind: .usage,
        category: .devTools,
        tier: .one,
        tierReason: "API 开发协作与测试平台近乎事实标准，份额远超同类工具。",
        colorKey: "postman",
        billingURL: URL(string: "https://go.postman.co/billing")!,
        credentialSetupURL: URL(string: "https://learning.postman.com/docs/developer/postman-api/authentication/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["postman", "invoices", "totalAmount", "x-api-key"]
    )

    public static let sevenbridges = ProviderDescriptor(
        id: .sevenbridges,
        displayName: "Seven Bridges",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "基因组学生物信息云平台的强挑战者，细分赛道里位居前列。",
        colorKey: "sevenbridges",
        billingURL: URL(string: "https://igor.sbgenomics.com")!,
        credentialSetupURL: URL(string: "https://docs.sevenbridges.com/reference/list-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["seven bridges", "sbgenomics", "cavatica", "billing invoices"]
    )

    public static let cmcom = ProviderDescriptor(
        id: .cmcom,
        displayName: "CM.com",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "欧洲 CPaaS/消息市场的强挑战者，与 Twilio 等同台。",
        colorKey: "cmcom",
        billingURL: URL(string: "https://www.cm.com")!,
        credentialSetupURL: URL(string: "https://developers.cm.com/messaging/docs/transactions-api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["cm.com", "cmcom", "transactions", "producttoken", "sms"]
    )
}
