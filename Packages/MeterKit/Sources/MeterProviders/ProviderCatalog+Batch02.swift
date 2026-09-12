import Foundation
import MeterCore

extension ProviderCatalog {
    public static let cohere = ProviderDescriptor(
        id: .cohere,
        displayName: "Cohere",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "企业 RAG 与私有化部署的稳定挑战者，规模小于三巨头和 Mistral。",
        colorKey: "cohere",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 没有账单金额。",
        searchKeywords: ["command", "cohere.ai"]
    )

    public static let gemini = ProviderDescriptor(
        id: .gemini,
        displayName: "Google Gemini",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "企业份额约两成、消费端约三成，与 OpenAI、Anthropic 构成全球前沿 API 寡头。",
        colorKey: "gemini",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Gemini API / AI Studio 没有给 API key 的账单接口。金额在 Cloud Billing，那是另一家。",
        searchKeywords: ["gemini", "ai studio", "google ai", "bard", "aistudio"]
    )

    public static let midjourney = ProviderDescriptor(
        id: .midjourney,
        displayName: "Midjourney",
        kind: .subscription,
        category: .aiInference,
        tier: .one,
        tierReason: "付费 AI 绘图的品类象征，自举且盈利，仍是图像生成独立品牌的寡头。",
        colorKey: "midjourney",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开 API，只能网页订阅。",
        searchKeywords: ["mj", "mid journey"]
    )

    public static let runway = ProviderDescriptor(
        id: .runway,
        displayName: "Runway",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "专业 AI 视频工具在中市场采购与支出上明显领先同类。",
        colorKey: "runway",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["runwayml", "gen-3", "gen-4", "video"]
    )

    public static let netlify = ProviderDescriptor(
        id: .netlify,
        displayName: "Netlify",
        kind: .planAndUsage,
        category: .hosting,
        tier: .four,
        tierReason: "Jamstack 开创者持续丢份额与心智，融资停在 2021，正在被 Vercel 替换为默认选项。",
        colorKey: "netlify",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有付款方式，没有发票金额。",
        searchKeywords: ["jamstack", "netlify.com"]
    )

    public static let supabase = ProviderDescriptor(
        id: .supabase,
        displayName: "Supabase",
        kind: .planAndUsage,
        category: .database,
        tier: .one,
        tierReason: "开源 Postgres BaaS 已与 Firebase 对分开发者后端，并成为 vibe-coding 默认库。",
        colorKey: "supabase",
        billingURL: URL(string: "https://supabase.com/dashboard/org/_/billing")!,
        credentialSetupURL: URL(string: "https://supabase.com/dashboard/account/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["postgres", "postgresql", "database", "数据库", "baas"]
    )

    public static let firebase = ProviderDescriptor(
        id: .firebase,
        displayName: "Firebase",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "移动 BaaS 仍由 Firebase 以数量级优势坐庄，Supabase 是挑战者而非对等寡头。",
        colorKey: "firebase",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单走 Google Cloud Billing，没有独立的 Firebase 账单接口。",
        searchKeywords: ["firestore", "fcm", "google"]
    )

    public static let linear = ProviderDescriptor(
        id: .linear,
        displayName: "Linear",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "工程师问题跟踪里增长最快的 Jira 挑战者，已过亿美元 ARR 且现金流为正。",
        colorKey: "linear",
        billingURL: URL(string: "https://linear.app/settings/plans")!,
        credentialSetupURL: URL(string: "https://linear.app/settings/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["linear.app", "issue", "项目管理"]
    )

    public static let notion = ProviderDescriptor(
        id: .notion,
        displayName: "Notion",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "知识库/工作区的强挑战者，收入已近十亿美元但仍面对 Google/Confluence。",
        colorKey: "notion",
        billingURL: URL(string: "https://www.notion.so/profile")!,
        credentialSetupURL: URL(string: "https://www.notion.so/my-integrations")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["notion.so", "wiki", "docs"]
    )

    public static let figma = ProviderDescriptor(
        id: .figma,
        displayName: "Figma",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "协作 UI 设计的事实标准，收入已过十亿美元且独立上市。",
        colorKey: "figma",
        billingURL: URL(string: "https://www.figma.com/settings")!,
        credentialSetupURL: URL(string: "https://help.figma.com/hc/en-us/articles/360039811114-Manage-your-plan")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["figma.com", "design", "设计"]
    )

    public static let slack = ProviderDescriptor(
        id: .slack,
        displayName: "Slack",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "科技公司团队聊天的付费寡头，与捆绑销售的 Teams 二分市场。",
        colorKey: "slack",
        billingURL: URL(string: "https://my.slack.com/admin/billing")!,
        credentialSetupURL: URL(string: "https://slack.com/help/articles/218915077-Manage-your-Slack-plan")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["slack.com", "聊天"]
    )

    public static let windsurf = ProviderDescriptor(
        id: .windsurf,
        displayName: "Windsurf",
        kind: .subscription,
        category: .aiInference,
        tier: .four,
        tierReason: "创始团队被谷歌挖走、产品被 Cognition 低价收编，职场份额个位数且下滑。",
        colorKey: "windsurf",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["codeium", "cascade", "ide", "编辑器"]
    )

    public static let mistral = ProviderDescriptor(
        id: .mistral,
        displayName: "Mistral",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "欧洲主权与私有化部署的主要独立挑战者，收入已到数亿美元但未进入全球支出寡头。",
        colorKey: "mistral",
        billingURL: URL(string: "https://admin.mistral.ai")!,
        credentialSetupURL: URL(string: "https://backoffice.mistral.ai")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["mistral ai", "mixtral", "le chat", "codestral"]
    )

    public static let fireworks = ProviderDescriptor(
        id: .fireworks,
        displayName: "Fireworks",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "生产级开源推理收入已过十亿美元，与 Together 分食该市场。",
        colorKey: "fireworks",
        billingURL: URL(string: "https://app.fireworks.ai")!,
        credentialSetupURL: URL(string: "https://app.fireworks.ai/settings/users/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["fireworks.ai", "fireworks ai", "inference"]
    )

    public static let fal = ProviderDescriptor(
        id: .fal,
        displayName: "fal.ai",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "生成式媒体推理的领先平台，年化收入已到数亿美元量级。",
        colorKey: "fal",
        billingURL: URL(string: "https://fal.ai/dashboard")!,
        credentialSetupURL: URL(string: "https://fal.ai/dashboard/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["fal", "fal.ai", "flux", "image"]
    )

    public static let huggingface = ProviderDescriptor(
        id: .huggingface,
        displayName: "Hugging Face",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "开源模型分发近乎垄断，推理 API 是附加能力。",
        colorKey: "huggingface",
        billingURL: URL(string: "https://huggingface.co/settings/billing")!,
        credentialSetupURL: URL(string: "https://huggingface.co/settings/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["hf", "huggingface", "inference", "spaces", "hub"]
    )

    public static let turso = ProviderDescriptor(
        id: .turso,
        displayName: "Turso",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "libSQL/SQLite 边缘库仍处早期，资金很少但产品仍在向 Postgres 前端扩张。",
        colorKey: "turso",
        billingURL: URL(string: "https://app.turso.tech")!,
        credentialSetupURL: URL(string: "https://docs.turso.tech/cli/auth/api-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["libsql", "sqlite", "database", "数据库"]
    )

    public static let gcp = ProviderDescriptor(
        id: .gcp,
        displayName: "Google Cloud",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "三大超大规模云之一，份额上升且增速快于市场，仍是企业短名单第三席。",
        colorKey: "gcp",
        billingURL: URL(string: "https://console.cloud.google.com/billing")!,
        credentialSetupURL: URL(string: "https://console.cloud.google.com/iam-admin/serviceaccounts")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["gcp", "google cloud", "gce", "gcs", "bigquery"]
    )

    public static let baseten = ProviderDescriptor(
        id: .baseten,
        displayName: "Baseten",
        kind: .usage,
        category: .gpuCompute,
        tier: .two,
        tierReason: "推理平台被企业当成 SageMaker/Vertex 的替代，收入一年内冲到数亿美元量级。",
        colorKey: "baseten",
        billingURL: URL(string: "https://app.baseten.co")!,
        credentialSetupURL: URL(string: "https://docs.baseten.co/organization/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["baseten.co", "truss", "inference"]
    )

    public static let clickhouse = ProviderDescriptor(
        id: .clickhouse,
        displayName: "ClickHouse Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "实时 OLAP 的最强独立挑战者，云收入一年内翻数倍并按 IPO 路径扩张。",
        colorKey: "clickhouse",
        billingURL: URL(string: "https://console.clickhouse.cloud")!,
        credentialSetupURL: URL(string: "https://clickhouse.com/docs/cloud/manage/openapi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["clickhouse cloud", "chc", "analytics", "olap"]
    )

    public static let linode = ProviderDescriptor(
        id: .linode,
        displayName: "Linode",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "Akamai 收购后云基础设施仍在高增，品牌仍是 VPS 常见替代，但体量小于 DO。",
        colorKey: "linode",
        billingURL: URL(string: "https://cloud.linode.com/account/billing")!,
        credentialSetupURL: URL(string: "https://cloud.linode.com/profile/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["akamai", "linode.com", "vps"]
    )

    public static let runpod = ProviderDescriptor(
        id: .runpod,
        displayName: "RunPod",
        kind: .prepaid,
        category: .gpuCompute,
        tier: .two,
        tierReason: "自助 GPU 云里开发者真正会下单的替代，实例供给和 ARR 都已是新云第二梯队。",
        colorKey: "runpod",
        billingURL: URL(string: "https://www.runpod.io/console/user/billing")!,
        credentialSetupURL: URL(string: "https://www.runpod.io/console/user/settings")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["runpod.io", "gpu", "serverless", "pod"]
    )
}
