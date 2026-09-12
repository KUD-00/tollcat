import Foundation
import MeterCore

extension ProviderCatalog {
    public static let workos = ProviderDescriptor(
        id: .workos,
        displayName: "WorkOS",
        kind: .subscription,
        category: .authSecurity,
        tier: .two,
        tierReason: "B2B SaaS 企业单点登录的开发者默认层。",
        colorKey: "workos",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["workos.com", "sso", "directory"]
    )

    public static let contentful = ProviderDescriptor(
        id: .contentful,
        displayName: "Contentful",
        kind: .planAndUsage,
        category: .cms,
        tier: .two,
        tierReason: "无头 CMS 份额第一，已被 Salesforce 收购并并入 Headless 360。",
        colorKey: "contentful",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["contentful.com", "cms", "headless"]
    )

    public static let cloudinary = ProviderDescriptor(
        id: .cloudinary,
        displayName: "Cloudinary",
        kind: .usage,
        category: .media,
        tier: .two,
        tierReason: "图像视频变换与 DAM 的领先挑战者，已达亿元级收入。",
        colorKey: "cloudinary",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有用量计数，没有账单金额。",
        searchKeywords: ["cloudinary.com", "image", "cdn"]
    )

    public static let sendgrid = ProviderDescriptor(
        id: .sendgrid,
        displayName: "SendGrid",
        kind: .planAndUsage,
        category: .messaging,
        tier: .one,
        tierReason: "事务邮件检测份额与发送量均居前列，属 Twilio 系寡头。",
        colorKey: "sendgrid",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有发送统计，没有账单金额。",
        searchKeywords: ["sendgrid.com", "twilio sendgrid", "email"]
    )

    public static let mailgun = ProviderDescriptor(
        id: .mailgun,
        displayName: "Mailgun",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "高发送量开发者邮件 API，紧随 SendGrid 的强挑战者。",
        colorKey: "mailgun",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有发送统计，没有账单金额。",
        searchKeywords: ["mailgun.com", "email"]
    )

    public static let lambdalabs = ProviderDescriptor(
        id: .lambdalabs,
        displayName: "Lambda",
        kind: .usage,
        category: .gpuCompute,
        tier: .two,
        tierReason: "开发者向 GPU 云的核心替代，已被 Synergy 点名为快速扩张的新云之一。",
        colorKey: "lambdalabs",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["lambda labs", "lambdalabs", "gpu"]
    )

    public static let novita = ProviderDescriptor(
        id: .novita,
        displayName: "Novita",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "廉价开源推理长尾云，公开融资与收入均远小于 Fireworks/Together。",
        colorKey: "novita",
        billingURL: URL(string: "https://novita.ai/billing")!,
        credentialSetupURL: URL(string: "https://novita.ai/settings/key-management")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["novita.ai", "gpu", "inference"]
    )

    public static let apify = ProviderDescriptor(
        id: .apify,
        displayName: "Apify",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "传统爬虫/自动化平台收入稳步千万级，但不是 AI 搜索新贵。",
        colorKey: "apify",
        billingURL: URL(string: "https://console.apify.com/billing")!,
        credentialSetupURL: URL(string: "https://console.apify.com/settings/integrations")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["apify.com", "actor", "crawler", "scraper"]
    )

    public static let tavily = ProviderDescriptor(
        id: .tavily,
        displayName: "Tavily",
        kind: .freeTier,
        category: .aiInference,
        tier: .two,
        tierReason: "曾是 Agent 搜索 API 双雄之一，被 Nebius 收购后独立公司消失、产品仍在。",
        colorKey: "tavily",
        billingURL: URL(string: "https://app.tavily.com")!,
        credentialSetupURL: URL(string: "https://docs.tavily.com/documentation/quickstart")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["tavily.com", "search", "search api"]
    )

    public static let deepinfra = ProviderDescriptor(
        id: .deepinfra,
        displayName: "DeepInfra",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "以低价开源推理抢量的强挑战者，已拿到过亿美元融资但仍非收入寡头。",
        colorKey: "deepinfra",
        billingURL: URL(string: "https://deepinfra.com/dash")!,
        credentialSetupURL: URL(string: "https://docs.deepinfra.com/account/authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["deepinfra.com", "inference", "gpu"]
    )

    public static let vastai = ProviderDescriptor(
        id: .vastai,
        displayName: "Vast.ai",
        kind: .prepaid,
        category: .gpuCompute,
        tier: .three,
        tierReason: "点对点 GPU 市场是预算盘常选项，供给可观但收入与可靠性都达不到行业替代量级。",
        colorKey: "vastai",
        billingURL: URL(string: "https://cloud.vast.ai")!,
        credentialSetupURL: URL(string: "https://cloud.vast.ai/manage-keys/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["vast.ai", "vastai", "gpu", "marketplace"]
    )

    public static let firecrawl = ProviderDescriptor(
        id: .firecrawl,
        displayName: "Firecrawl",
        kind: .freeTier,
        category: .aiInference,
        tier: .three,
        tierReason: "AI 爬取转 Markdown 的开发者新秀，规模仍小。",
        colorKey: "firecrawl",
        billingURL: URL(string: "https://www.firecrawl.dev/app/billing")!,
        credentialSetupURL: URL(string: "https://www.firecrawl.dev/app/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["firecrawl.dev", "scrape", "crawl"]
    )

    public static let cockroach = ProviderDescriptor(
        id: .cockroach,
        displayName: "CockroachDB Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "独立分布式 SQL 的企业级代表，融资估值高但近年无新一轮、排名偏后。",
        colorKey: "cockroach",
        billingURL: URL(string: "https://cockroachlabs.cloud")!,
        credentialSetupURL: URL(string: "https://www.cockroachlabs.com/docs/cockroachcloud/managing-access")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["cockroachdb", "cockroach labs", "crdb", "postgres"]
    )

    public static let typesense = ProviderDescriptor(
        id: .typesense,
        displayName: "Typesense Cloud",
        kind: .usage,
        category: .search,
        tier: .three,
        tierReason: "零融资仍能靠 Cloud 养活的开源搜索，体量比 Algolia/Elastic 小一个数量级。",
        colorKey: "typesense",
        billingURL: URL(string: "https://cloud.typesense.org")!,
        credentialSetupURL: URL(string: "https://typesense.org/docs/cloud-management-api/v1/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["typesense.org", "search", "search engine"]
    )

    public static let cerebras = ProviderDescriptor(
        id: .cerebras,
        displayName: "Cerebras",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "晶圆级推理的独特挑战者，拿得到大单但不是通用 LLM API 寡头。",
        colorKey: "cerebras",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预充值只在控制台，没有公开余额接口。",
        searchKeywords: ["cerebras.ai", "inference", "wafer"]
    )

    public static let cartesia = ProviderDescriptor(
        id: .cartesia,
        displayName: "Cartesia",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "实时 TTS 延迟与音质标杆，融资近两亿美元，但收入体量远小于 ElevenLabs。",
        colorKey: "cartesia",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "TTS 是 credits，Agent 才是美元，没有一份能对账的总账单。",
        searchKeywords: ["cartesia.ai", "tts", "sonic", "voice"]
    )

    public static let helicone = ProviderDescriptor(
        id: .helicone,
        displayName: "Helicone",
        kind: .usage,
        category: .aiInference,
        tier: .four,
        tierReason: "开源网关型观测规模远小于 Langfuse，且有被收购后进入维护模式的报道。",
        colorKey: "helicone",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 估的是下游 LLM 花费，不是付给 Helicone 的账单。",
        searchKeywords: ["helicone.ai", "llm ops", "gateway"]
    )

    public static let wasabi = ProviderDescriptor(
        id: .wasabi,
        displayName: "Wasabi",
        kind: .usage,
        category: .storage,
        tier: .two,
        tierReason: "独立廉价对象存储的领先挑战者，客户与收入均大于 B2。",
        colorKey: "wasabi",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额只在合作伙伴 WACM，客户没有账单接口。",
        searchKeywords: ["wasabi.com", "object storage", "s3"]
    )

    public static let coreweave = ProviderDescriptor(
        id: .coreweave,
        displayName: "CoreWeave",
        kind: .usage,
        category: .gpuCompute,
        tier: .one,
        tierReason: "GPU 云新云里体量碾压同侪，与超大规模云一起切走企业级 GPU 训练/推理订单。",
        colorKey: "coreweave",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单只在控制台，公开接口没有账单金额。",
        searchKeywords: ["coreweave.com", "gpu", "kubernetes"]
    )

    public static let honeycomb = ProviderDescriptor(
        id: .honeycomb,
        displayName: "Honeycomb",
        kind: .usage,
        category: .observability,
        tier: .three,
        tierReason: "高基数查询的远见者，规模远小于 Datadog/Grafana，但仍连年留在分析师视野象限。",
        colorKey: "honeycomb",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["honeycomb.io", "observability", "tracing"]
    )

    public static let newrelic = ProviderDescriptor(
        id: .newrelic,
        displayName: "New Relic",
        kind: .usage,
        category: .observability,
        tier: .two,
        tierReason: "仍是可观测平台的大型在位者，但企业支出意愿已掉到垫底。",
        colorKey: "newrelic",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "NerdGraph / NRQL 只给 GB 和席位，金额要自己乘单价。",
        searchKeywords: ["new relic", "newrelic.com", "apm", "observability"]
    )

    public static let weaviate = ProviderDescriptor(
        id: .weaviate,
        displayName: "Weaviate Cloud",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "混合检索向量库仍有机构加持，但开源热度与融资估值已落后于 Qdrant。",
        colorKey: "weaviate",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["weaviate.io", "vector", "wcd"]
    )

    public static let triggerdev = ProviderDescriptor(
        id: .triggerdev,
        displayName: "Trigger.dev",
        kind: .usage,
        category: .automation,
        tier: .three,
        tierReason: "TypeScript 持久任务的小型开源挑战者，社区热度高于 Inngest 但仍是利基。",
        colorKey: "triggerdev",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["trigger.dev", "jobs", "background"]
    )

    public static let aiven = ProviderDescriptor(
        id: .aiven,
        displayName: "Aiven",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "独立托管开源数据平台已过亿美元 ARR，是云厂商托管 Kafka/Postgres 的主要替代。",
        colorKey: "aiven",
        billingURL: URL(string: "https://console.aiven.io")!,
        credentialSetupURL: URL(string: "https://aiven.io/docs/platform/howto/create_authentication_token")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["aiven.io", "kafka", "opensearch", "postgres", "mysql"]
    )

    public static let siliconflow = ProviderDescriptor(
        id: .siliconflow,
        displayName: "SiliconFlow",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "中国最大独立 token 工厂，但全国份额仅约 1.5%，收入仍很小。",
        colorKey: "siliconflow",
        billingURL: URL(string: "https://cloud.siliconflow.cn/account/billing")!,
        credentialSetupURL: URL(string: "https://cloud.siliconflow.cn/account/ak")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["硅基流动", "silicon flow", "siliconcloud", "国内"]
    )
}
