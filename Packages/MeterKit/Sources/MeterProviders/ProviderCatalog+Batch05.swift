import Foundation
import MeterCore

extension ProviderCatalog {
    public static let aimlapi = ProviderDescriptor(
        id: .aimlapi,
        displayName: "AI/ML API",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "无融资的多模型聚合器，体量远小于 OpenRouter，属长尾网关。",
        colorKey: "aimlapi",
        billingURL: URL(string: "https://aimlapi.com/app/billing")!,
        credentialSetupURL: URL(string: "https://aimlapi.com/app/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["aimlapi", "ai/ml api", "aiml"]
    )

    public static let stepfun = ProviderDescriptor(
        id: .stepfun,
        displayName: "StepFun (China)",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "有上市路径和多模态产品，但网关份额与收入仍明显落后月之暗面、智谱、MiniMax。",
        colorKey: "stepfun",
        billingURL: URL(string: "https://platform.stepfun.com/console/billing")!,
        credentialSetupURL: URL(string: "https://platform.stepfun.com/console/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["阶跃星辰", "stepfun", "step-1", "国内", "china"]
    )

    public static let stepfunAI = ProviderDescriptor(
        id: .stepfunAI,
        displayName: "StepFun (Overseas)",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "与国内阶跃星辰同一公司的海外 API，份额与收入仍属第二阵营之后的成长股。",
        colorKey: "stepfunai",
        billingURL: URL(string: "https://platform.stepfun.ai/console/billing")!,
        credentialSetupURL: URL(string: "https://platform.stepfun.ai/console/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["阶跃星辰", "stepfun", "step-1", "海外", "国际", "oversea", "overseas"]
    )

    public static let telnyx = ProviderDescriptor(
        id: .telnyx,
        displayName: "Telnyx",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "自建全球 IP 网的新晋利基玩家，刚进入分析师象限。",
        colorKey: "telnyx",
        billingURL: URL(string: "https://portal.telnyx.com/#/app/billing")!,
        credentialSetupURL: URL(string: "https://portal.telnyx.com/#/app/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["telnyx.com", "sip", "sms", "voice", "telecom"]
    )

    public static let minimax = ProviderDescriptor(
        id: .minimax,
        displayName: "MiniMax",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "上市后 B2B/API 收入快速爬升、网关份额进入第一梯队，但仍未分食企业支出寡头。",
        colorKey: "minimax",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Token Plan 接口只给配额窗口，不是按量美元余额。",
        searchKeywords: ["minimax.io", "minimax.com", "abab", "海螺"]
    )

    public static let hyperbolic = ProviderDescriptor(
        id: .hyperbolic,
        displayName: "Hyperbolic",
        kind: .prepaid,
        category: .gpuCompute,
        tier: .three,
        tierReason: "开放 GPU 市场仍是早期小盘，有融资但远未进入企业 GPU 短名单。",
        colorKey: "hyperbolic",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开余额或账单金额接口。",
        searchKeywords: ["hyperbolic.xyz", "gpu", "inference"]
    )

    public static let jina = ProviderDescriptor(
        id: .jina,
        displayName: "Jina",
        kind: .prepaid,
        category: .aiInference,
        tier: .three,
        tierReason: "Reader 等 API 有开发者口碑，但已被 Elastic 收编，独立体量小于 Exa/Tavily。",
        colorKey: "jina",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["jina.ai", "embeddings", "reader"]
    )

    public static let dashscope = ProviderDescriptor(
        id: .dashscope,
        displayName: "DashScope",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "中国企业级 token 市占领先，通义千问是国内 MaaS 寡头之一。",
        colorKey: "dashscope",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单走阿里云 BSS 整云账号，没有单独的通义账单接口。",
        searchKeywords: ["通义", "qwen", "aliyun", "alibaba", "dashscope"]
    )

    public static let paperspace = ProviderDescriptor(
        id: .paperspace,
        displayName: "Paperspace",
        kind: .usage,
        category: .gpuCompute,
        tier: .four,
        tierReason: "品牌已被 DigitalOcean 收编并导向 GPU Droplets，独立 GPU 云轨迹结束。",
        colorKey: "paperspace",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["paperspace.com", "gradient", "gpu"]
    )

    public static let salad = ProviderDescriptor(
        id: .salad,
        displayName: "Salad",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "闲置消费级 GPU 网络仍在运营，但规模停留在分布式算力长尾。",
        colorKey: "salad",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["salad.com", "saladcloud", "gpu"]
    )

    public static let browserbase = ProviderDescriptor(
        id: .browserbase,
        displayName: "Browserbase",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "浏览器基础设施新秀，会话量在涨但收入仍小，属于有前景的第三梯队。",
        colorKey: "browserbase",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["browserbase.com", "browser", "playwright"]
    )

    public static let convex = ProviderDescriptor(
        id: .convex,
        displayName: "Convex",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "响应式 TypeScript 后端在 AI 编程潮中融资加速，体量仍远小于 Supabase。",
        colorKey: "convex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["convex.dev", "backend", "database"]
    )

    public static let langfuse = ProviderDescriptor(
        id: .langfuse,
        displayName: "Langfuse",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "开源 LLM 观测的默认选项，品类仍小、尚未进入通用可观测寡头。",
        colorKey: "langfuse",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["langfuse.com", "llm ops", "observability"]
    )

    public static let gcore = ProviderDescriptor(
        id: .gcore,
        displayName: "Gcore",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "CDN+边缘/GPU 云收入过亿美元且两年近翻倍，仍是挑战者而非该品类寡头。",
        colorKey: "gcore",
        billingURL: URL(string: "https://gcore.com/cloud")!,
        credentialSetupURL: URL(string: "https://docs.gcore.com/account-settings/api-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["gcore.com", "cdn", "gpu", "reservation"]
    )

    public static let contabo = ProviderDescriptor(
        id: .contabo,
        displayName: "Contabo",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "德国廉价 VPS 长尾品牌仍有爱好者盘，但未进入主流云份额统计。",
        colorKey: "contabo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["contabo.com", "vps"]
    )

    public static let northflank = ProviderDescriptor(
        id: .northflank,
        displayName: "Northflank",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "BYOC/微服务 PaaS 有产品完成度，但仍是小而美，尚未进入主流替代短名单。",
        colorKey: "northflank",
        billingURL: URL(string: "https://app.northflank.com/")!,
        credentialSetupURL: URL(string: "https://app.northflank.com/s/account/api/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["northflank.com", "paas"]
    )

    public static let inngest = ProviderDescriptor(
        id: .inngest,
        displayName: "Inngest",
        kind: .usage,
        category: .automation,
        tier: .three,
        tierReason: "事件驱动持久工作流的利基玩家，规模与知名度都小于 Trigger.dev 与 n8n。",
        colorKey: "inngest",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["inngest.com", "jobs", "background"]
    )

    public static let tinybird = ProviderDescriptor(
        id: .tinybird,
        displayName: "Tinybird",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "托管 ClickHouse 分析层在母公司云业务爆发后被挤压，2025 年裁员一半。",
        colorKey: "tinybird",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["tinybird.co", "analytics", "clickhouse"]
    )

    public static let livekit = ProviderDescriptor(
        id: .livekit,
        displayName: "LiveKit",
        kind: .usage,
        category: .media,
        tier: .two,
        tierReason: "实时音视频与语音 AI 基建的爆发挑战者，已承接 ChatGPT 语音。",
        colorKey: "livekit",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["livekit.io", "webrtc", "video"]
    )

    public static let meilisearch = ProviderDescriptor(
        id: .meilisearch,
        displayName: "Meilisearch Cloud",
        kind: .usage,
        category: .search,
        tier: .three,
        tierReason: "MIT 开源即时搜索的有资金挑战者，社区大于 Typesense 但仍远小于 Algolia。",
        colorKey: "meilisearch",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单只在控制台，没有公开账单金额接口。",
        searchKeywords: ["meilisearch.com", "search"]
    )

    public static let motherduck = ProviderDescriptor(
        id: .motherduck,
        displayName: "MotherDuck",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "DuckDB 云化代表，融资与引擎热度上升，但相对 Snowflake/BigQuery 仍是小玩家。",
        colorKey: "motherduck",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有 CU 小时，没有账单金额。",
        searchKeywords: ["motherduck.com", "duckdb"]
    )

    public static let zhipu = ProviderDescriptor(
        id: .zhipu,
        displayName: "Zhipu",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "港股上市后 API 收入与网关流量均进入全球前五，是最强的非寡头挑战者之一。",
        colorKey: "zhipu",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口没有一份能对账的总账单，只有套餐配额。",
        searchKeywords: ["智谱", "glm", "z.ai", "bigmodel", "chatglm"]
    )

    public static let mariadb = ProviderDescriptor(
        id: .mariadb,
        displayName: "MariaDB Cloud",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "引擎仍居前二十，但公司 SPAC 后被私有化、云业务几经分拆回购，份额远小于 RDS/Aurora。",
        colorKey: "mariadb",
        billingURL: URL(string: "https://app.skysql.com")!,
        credentialSetupURL: URL(string: "https://app.skysql.com/user-profile/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["skysql", "mariadb.com", "mysql", "数据库"]
    )

    public static let ionos = ProviderDescriptor(
        id: .ionos,
        displayName: "IONOS Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "欧洲主机龙头的 Cloud 业务在增长，但只占集团约一成，IaaS 份额远落后市场增速。",
        colorKey: "ionos",
        billingURL: URL(string: "https://dcd.ionos.com")!,
        credentialSetupURL: URL(
            string: "https://docs.ionos.com/cloud/set-up-ionos-cloud/management/identity-access-management/token-manager"
        )!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["ionos.com", "1and1", "1&1", "dcd"]
    )

    public static let upcloud = ProviderDescriptor(
        id: .upcloud,
        displayName: "UpCloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "北欧高性能 VPS 利基玩家，有区域口碑但融资与体量长期停在小型独立云。",
        colorKey: "upcloud",
        billingURL: URL(string: "https://hub.upcloud.com")!,
        credentialSetupURL: URL(string: "https://upcloud.com/docs/guides/managing-api-tokens/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["upcloud.com", "maximap", "芬兰"]
    )

    public static let confluent = ProviderDescriptor(
        id: .confluent,
        displayName: "Confluent Cloud",
        kind: .usage,
        category: .database,
        tier: .one,
        tierReason: "Kafka 商业化寡头，云收入过半，已被 IBM 收购。",
        colorKey: "confluent",
        billingURL: URL(string: "https://confluent.cloud/settings/billing")!,
        credentialSetupURL: URL(string: "https://confluent.cloud/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["kafka", "confluent.cloud", "ksql", "flink"]
    )
}
