import Foundation
import MeterCore

extension ProviderCatalog {
    public static let alchemy = ProviderDescriptor(
        id: .alchemy,
        displayName: "Alchemy",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "以太坊/多链节点与增强 API 的强挑战者，开发者 Web3 基建短名单。",
        colorKey: "alchemy",
        billingURL: URL(string: "https://dashboard.alchemy.com/")!,
        credentialSetupURL: URL(string: "https://www.alchemy.com/docs/admin-api/usage/get-usage-summary")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["alchemy", "web3", "usage summary", "USD", "CU"]
    )

    public static let friendli = ProviderDescriptor(
        id: .friendli,
        displayName: "FriendliAI",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "韩国推理/GPU 服务的细分选手，体量小于 Fireworks / Together 主流短名单。",
        colorKey: "friendli",
        billingURL: URL(string: "https://friendli.ai/")!,
        credentialSetupURL: URL(string: "https://friendli.ai/docs/openapi/administration/cost")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["friendli", "friendliai", "team cost", "USD", "GPU"]
    )

    public static let mixpeek = ProviderDescriptor(
        id: .mixpeek,
        displayName: "Mixpeek",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "多模态检索/抽取 API 的细分选手，体量小于主流向量与推理短名单。",
        colorKey: "mixpeek",
        billingURL: URL(string: "https://mixpeek.com/")!,
        credentialSetupURL: URL(string: "https://docs.mixpeek.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["mixpeek", "spending-caps", "current_spending_usd", "multimodal"]
    )

    public static let typebot = ProviderDescriptor(
        id: .typebot,
        displayName: "Typebot",
        kind: .usage,
        category: .automation,
        tier: .three,
        tierReason: "开源对话流/表单机器人的细分选手，订阅体量小于主流 bot 平台。",
        colorKey: "typebot",
        billingURL: URL(string: "https://app.typebot.io/")!,
        credentialSetupURL: URL(string: "https://docs.typebot.com/api-reference/billing/list-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["typebot", "invoices", "stripe subtotal", "workspaceId"]
    )

    public static let botpress = ProviderDescriptor(
        id: .botpress,
        displayName: "Botpress",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "对话机器人与 Agent 平台的强挑战者，开发者 bot 基建短名单。",
        colorKey: "botpress",
        billingURL: URL(string: "https://botpress.com/")!,
        credentialSetupURL: URL(string: "https://www.botpress.com/docs/api-reference/admin-api/concepts/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["botpress", "upcoming-invoice", "totalInCents", "workspace"]
    )

    public static let seeweb = ProviderDescriptor(
        id: .seeweb,
        displayName: "Seeweb",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "意大利云主机/GPU 的区域选手，体量小于西欧主流 IaaS 短名单。",
        colorKey: "seeweb",
        billingURL: URL(string: "https://www.seeweb.it/")!,
        credentialSetupURL: URL(string: "https://docs.seeweb.it/en/hosting/cloudserver/rest-api/API-Endpoints/Billing/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["seeweb", "ecs", "billing servers", "EUR", "X-APITOKEN"]
    )

    public static let parasail = ProviderDescriptor(
        id: .parasail,
        displayName: "Parasail",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "Serverless/Dedicated GPU 推理的细分选手，体量小于 Fireworks / Together 主流短名单。",
        colorKey: "parasail",
        billingURL: URL(string: "https://www.parasail.io/")!,
        credentialSetupURL: URL(string: "https://docs.parasail.io/parasail-docs/api-reference/billing-api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["parasail", "invoices", "current", "USD", "GPU"]
    )
}
