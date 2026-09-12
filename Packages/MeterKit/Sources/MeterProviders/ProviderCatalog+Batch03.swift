import Foundation
import MeterCore

extension ProviderCatalog {
    public static let deepgram = ProviderDescriptor(
        id: .deepgram,
        displayName: "Deepgram",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "生产级流式语音识别的默认供应商，与 ElevenLabs 分食独立语音 API 寡头。",
        colorKey: "deepgram",
        billingURL: URL(string: "https://console.deepgram.com")!,
        credentialSetupURL: URL(string: "https://developers.deepgram.com/docs/create-additional-api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["deepgram.com", "speech", "stt", "tts", "语音", "billing/breakdown"]
    )

    public static let scaleway = ProviderDescriptor(
        id: .scaleway,
        displayName: "Scaleway",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "Iliad 旗下欧洲主权云在扩区、加码 AI，但规模仍远小于超大规模云和 OVH。",
        colorKey: "scaleway",
        billingURL: URL(string: "https://console.scaleway.com/billing")!,
        credentialSetupURL: URL(string: "https://console.scaleway.com/iam/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["scaleway.com", "online.net", "france", "vps"]
    )

    public static let pinecone = ProviderDescriptor(
        id: .pinecone,
        displayName: "Pinecone",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "托管向量库仍是品类默认选择，但 pgvector 与开源库正在分走份额、增长放缓。",
        colorKey: "pinecone",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "用量和发票只在控制台，公开 API 没有账单金额。",
        searchKeywords: ["pinecone.io", "vector", "向量", "rag"]
    )

    public static let modal = ProviderDescriptor(
        id: .modal,
        displayName: "Modal",
        kind: .usage,
        category: .gpuCompute,
        tier: .two,
        tierReason: "无服务器 GPU/作业平台已被当成可规模化的替代，ARR 已到数亿美元。",
        colorKey: "modal",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有 Python SDK / CLI，没有 HTTP 账单金额。",
        searchKeywords: ["modal.com", "gpu", "serverless"]
    )

    public static let hetzner = ProviderDescriptor(
        id: .hetzner,
        displayName: "Hetzner",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "欧洲廉价 VPS/云的事实标准选项，实例规模与营收都已是独立云第一梯队。",
        colorKey: "hetzner",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Cloud API 只有价目，没有本月花费。",
        searchKeywords: ["hetzner cloud", "hcloud", "robot"]
    )

    public static let auth0 = ProviderDescriptor(
        id: .auth0,
        displayName: "Auth0",
        kind: .subscription,
        category: .authSecurity,
        tier: .two,
        tierReason: "中市值 SaaS 的 CIAM 默认选项，归入 Okta 后仍是开发者身份的强在位者。",
        colorKey: "auth0",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["auth0.com", "okta", "identity"]
    )

    public static let mixpanel = ProviderDescriptor(
        id: .mixpanel,
        displayName: "Mixpanel",
        kind: .planAndUsage,
        category: .analytics,
        tier: .two,
        tierReason: "产品分析老牌玩家，收入仍大但中小客户份额被 PostHog 切走。",
        colorKey: "mixpanel",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["mixpanel.com", "analytics", "产品分析"]
    )

    public static let amplitude = ProviderDescriptor(
        id: .amplitude,
        displayName: "Amplitude",
        kind: .planAndUsage,
        category: .analytics,
        tier: .two,
        tierReason: "上市的企业产品分析在位者，增速稳健但远低于 PostHog。",
        colorKey: "amplitude",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["amplitude.com", "analytics", "产品分析"]
    )

    public static let launchdarkly = ProviderDescriptor(
        id: .launchdarkly,
        displayName: "LaunchDarkly",
        kind: .subscription,
        category: .devTools,
        tier: .one,
        tierReason: "企业功能开关与运行时控制的品类龙头，规模与心智仍压过开源和套件捆绑者。",
        colorKey: "launchdarkly",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["launchdarkly.com", "feature flag", "flags"]
    )

    public static let algolia = ProviderDescriptor(
        id: .algolia,
        displayName: "Algolia",
        kind: .planAndUsage,
        category: .search,
        tier: .two,
        tierReason: "站点搜索 API 的龙头之一，收入过亿美元但增速已降至约一成、估值被下调。",
        colorKey: "algolia",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 没有账单金额。",
        searchKeywords: ["algolia.com", "search", "搜索"]
    )

    public static let zapier = ProviderDescriptor(
        id: .zapier,
        displayName: "Zapier",
        kind: .subscription,
        category: .automation,
        tier: .one,
        tierReason: "无代码应用自动化的默认寡头，中市场渗透仍远高于 n8n/Make。",
        colorKey: "zapier",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["zapier.com", "automation", "自动化"]
    )

    public static let discord = ProviderDescriptor(
        id: .discord,
        displayName: "Discord",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "开发者/游戏社区通讯的默认平台，用户巨大但估值较 2021 高点明显回落。",
        colorKey: "discord",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开服务器账单接口。商标条款也不许改色改 path，字母回落。",
        searchKeywords: ["discord.com", "nitro"]
    )

    public static let replit = ProviderDescriptor(
        id: .replit,
        displayName: "Replit",
        kind: .planAndUsage,
        category: .hosting,
        tier: .two,
        tierReason: "AI 编程+一键托管爆发后成为大量应用的实际落地点，是该工作流里被点名的替代。",
        colorKey: "replit",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["replit.com", "repl.it", "ide"]
    )

    public static let webflow = ProviderDescriptor(
        id: .webflow,
        displayName: "Webflow",
        kind: .subscription,
        category: .cms,
        tier: .two,
        tierReason: "专业可视化建站的领先者，在 CMS 总盘里份额稳定但远小于 WordPress。",
        colorKey: "webflow",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["webflow.com", "cms"]
    )

    public static let snowflake = ProviderDescriptor(
        id: .snowflake,
        displayName: "Snowflake",
        kind: .usage,
        category: .database,
        tier: .one,
        tierReason: "云数仓寡头之一，产品收入已达数十亿美元并继续抬高全年指引。",
        colorKey: "snowflake",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有给客户的 HTTP 账单金额接口。",
        searchKeywords: ["snowflake.com", "warehouse", "data cloud"]
    )

    public static let intercom = ProviderDescriptor(
        id: .intercom,
        displayName: "Intercom",
        kind: .subscription,
        category: .messaging,
        tier: .two,
        tierReason: "SaaS 客户消息与 AI 客服的强挑战者，整体客服市场仍由 Zendesk 领跑。",
        colorKey: "intercom",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["intercom.com", "inbox", "客服"]
    )

    public static let bunny = ProviderDescriptor(
        id: .bunny,
        displayName: "bunny.net",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "低价 CDN 与视频边缘正在爬升，份额仍约百分之一。",
        colorKey: "bunny",
        billingURL: URL(string: "https://dash.bunny.net")!,
        credentialSetupURL: URL(string: "https://docs.bunny.net/account/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["bunny.net", "bunnycdn", "cdn"]
    )

    public static let grafana = ProviderDescriptor(
        id: .grafana,
        displayName: "Grafana Cloud",
        kind: .planAndUsage,
        category: .observability,
        tier: .one,
        tierReason: "开源可观测栈的商业化寡头之一，连续三年进入 Gartner 领导者象限。",
        colorKey: "grafana",
        billingURL: URL(string: "https://grafana.com/orgs")!,
        credentialSetupURL: URL(
            string: "https://grafana.com/docs/grafana-cloud/security-and-account-management/authentication-and-permissions/access-policies/create-access-policies/"
        )!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["grafana cloud", "loki", "tempo", "mimir"]
    )

    public static let elastic = ProviderDescriptor(
        id: .elastic,
        displayName: "Elastic Cloud",
        kind: .usage,
        category: .search,
        tier: .one,
        tierReason: "搜索引擎与托管搜索的寡头，年收入近 20 亿美元且 Elastic Cloud 接近一半。",
        colorKey: "elastic",
        billingURL: URL(string: "https://cloud.elastic.co/account")!,
        credentialSetupURL: URL(string: "https://www.elastic.co/docs/api/doc/cloud-billing/authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["elasticsearch", "kibana", "ecu", "elastic cloud"]
    )

    public static let datadog = ProviderDescriptor(
        id: .datadog,
        displayName: "Datadog",
        kind: .usage,
        category: .observability,
        tier: .one,
        tierReason: "云原生可观测的执行力最强寡头，收入规模甩开同业一个数量级。",
        colorKey: "datadog",
        billingURL: URL(string: "https://app.datadoghq.com/billing")!,
        credentialSetupURL: URL(string: "https://app.datadoghq.com/organization-settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["datadoghq", "apm", "logs", "monitor"],
        guideURLs: [
            "applicationKeys": URL(
                string: "https://app.datadoghq.com/organization-settings/application-keys"
            )!,
        ]
    )

    public static let backblaze = ProviderDescriptor(
        id: .backblaze,
        displayName: "Backblaze",
        kind: .usage,
        category: .storage,
        tier: .three,
        tierReason: "独立对象存储里增长最快之一，相对 S3 仍是利基。",
        colorKey: "backblaze",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单只在控制台和合作伙伴 CSV，没有账单金额接口。",
        searchKeywords: ["b2", "backblaze b2", "storage"]
    )

    public static let assemblyai = ProviderDescriptor(
        id: .assemblyai,
        displayName: "AssemblyAI",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "语音转写基础设施的强挑战者，调用量大但估值与定位仍低于 Deepgram。",
        colorKey: "assemblyai",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预充值只在控制台，没有公开余额接口。",
        searchKeywords: ["assemblyai.com", "speech", "stt", "语音"]
    )

    public static let mux = ProviderDescriptor(
        id: .mux,
        displayName: "Mux",
        kind: .usage,
        category: .media,
        tier: .four,
        tierReason: "开发者视频 API 收入自 2021 峰值后停滞。",
        colorKey: "mux",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Delivery Usage 只给秒数，没有账单金额。",
        searchKeywords: ["mux.com", "video", "stream"]
    )

    public static let civo = ProviderDescriptor(
        id: .civo,
        displayName: "Civo",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "英国 Kubernetes 简云有增长苗头，但年收入仍是千万级，远未成为行业替代选项。",
        colorKey: "civo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Charges API 只给小时数，没有账单金额。",
        searchKeywords: ["civo.com", "kubernetes", "k3s"]
    )

    public static let koyeb = ProviderDescriptor(
        id: .koyeb,
        displayName: "Koyeb",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "独立容器 PaaS 已被 Mistral 收购并并入其 AI 基建，该品牌在托管市场的独立轨迹结束。",
        colorKey: "koyeb",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["koyeb.com", "gpu", "serverless"]
    )

    public static let pagerduty = ProviderDescriptor(
        id: .pagerduty,
        displayName: "PagerDuty",
        kind: .subscription,
        category: .observability,
        tier: .two,
        tierReason: "仍是企业值班/事件响应的默认品牌，但净留存跌破 100%、ARR 几乎停滞。",
        colorKey: "pagerduty",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单接口。",
        searchKeywords: ["pagerduty.com", "oncall", "incident"]
    )
}
