import Foundation
import MeterCore

extension ProviderCatalog {
    public static let railway = ProviderDescriptor(
        id: .railway,
        displayName: "Railway",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "开发者口中的现代 Heroku，自建机房后增长很快，已被当成可落地的替代。",
        colorKey: "railway",
        billingURL: URL(string: "https://railway.com/workspace/usage")!,
        credentialSetupURL: URL(string: "https://railway.com/account/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["railway.app", "deploy", "部署"]
    )

    public static let stripe = ProviderDescriptor(
        id: .stripe,
        displayName: "Stripe",
        kind: .usage,
        category: .payments,
        tier: .one,
        tierReason: "开发者收单与订阅计费的基础设施寡头，处理量已进入全球支付第一梯队。",
        colorKey: "stripe",
        billingURL: URL(string: "https://dashboard.stripe.com/balance")!,
        credentialSetupURL: URL(string: "https://dashboard.stripe.com/apikeys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["支付", "手续费", "payments", "收费"]
    )

    public static let resend = ProviderDescriptor(
        id: .resend,
        displayName: "Resend",
        kind: .freeTier,
        category: .messaging,
        tier: .two,
        tierReason: "开发者事务邮件的默认新选择，正在快速抢 SendGrid 的心智。",
        colorKey: "resend",
        billingURL: URL(string: "https://resend.com/settings/usage")!,
        credentialSetupURL: URL(string: "https://resend.com/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["email", "邮件", "transactional"]
    )

    public static let posthog = ProviderDescriptor(
        id: .posthog,
        displayName: "PostHog",
        kind: .usage,
        category: .analytics,
        tier: .two,
        tierReason: "开发者一体分析正在吞噬 Mixpanel/Amplitude 的中小客户，增速远高于在位者。",
        colorKey: "posthog",
        billingURL: URL(string: "https://app.posthog.com/organization/billing")!,
        credentialSetupURL: URL(string: "https://app.posthog.com/settings/user-api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["analytics", "分析", "replay", "feature flags"]
    )

    public static let clerk = ProviderDescriptor(
        id: .clerk,
        displayName: "Clerk",
        kind: .planAndUsage,
        category: .authSecurity,
        tier: .two,
        tierReason: "Next.js / React 开发者认证的默认替代，正在切 Auth0 的中小客户。",
        colorKey: "clerk",
        billingURL: URL(string: "https://dashboard.clerk.com/last-active?path=billing")!,
        credentialSetupURL: URL(string: "https://dashboard.clerk.com/last-active?path=api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["auth", "登录", "authentication", "mau", "mru"]
    )

    public static let sentry = ProviderDescriptor(
        id: .sentry,
        displayName: "Sentry",
        kind: .freeTier,
        category: .observability,
        tier: .one,
        tierReason: "错误追踪几乎是事实标准，份额远超 Bugsnag/Rollbar 等竞品。",
        colorKey: "sentry",
        billingURL: URL(string: "https://sentry.io/settings/billing/overview/")!,
        credentialSetupURL: URL(string: "https://sentry.io/settings/account/api/auth-tokens/new-token/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .available,
        searchKeywords: ["error", "错误", "crash", "监控"]
    )

    public static let vultr = ProviderDescriptor(
        id: .vultr,
        displayName: "Vultr",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "北美开发者常把它与 DO/Linode 并列短名单，并已进入主流公有云评测。",
        colorKey: "vultr",
        billingURL: URL(string: "https://my.vultr.com/billing")!,
        credentialSetupURL: URL(string: "https://my.vultr.com/settings/#settingsapi")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["vps", "cloud compute", "主机", "云服务器"]
    )

    public static let fastly = ProviderDescriptor(
        id: .fastly,
        displayName: "Fastly",
        kind: .usage,
        category: .networkEdge,
        tier: .two,
        tierReason: "可编程 CDN 的强挑战者，收入回升但站点份额被 Cloudflare 侵蚀。",
        colorKey: "fastly",
        billingURL: URL(string: "https://manage.fastly.com/account/billing")!,
        credentialSetupURL: URL(string: "https://manage.fastly.com/account/personal/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["cdn", "edge", "compute@edge", "加速"]
    )

    public static let exa = ProviderDescriptor(
        id: .exa,
        displayName: "Exa",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "AI 搜索 API 里融资与客户质量最高的挑战者，但收入仍远小于 Perplexity。",
        colorKey: "exa",
        billingURL: URL(string: "https://dashboard.exa.ai/billing")!,
        credentialSetupURL: URL(string: "https://dashboard.exa.ai/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["search", "搜索", "agent", "metaphor"]
    )

    public static let atlas = ProviderDescriptor(
        id: .atlas,
        displayName: "MongoDB Atlas",
        kind: .usage,
        category: .database,
        tier: .one,
        tierReason: "文档库云市场的寡头核心，Atlas 已占 MongoDB 七成以上收入并持续双位数增长。",
        colorKey: "atlas",
        billingURL: URL(string: "https://cloud.mongodb.com/v2#/billing/overview")!,
        credentialSetupURL: URL(string: "https://cloud.mongodb.com/v2#/access/serviceAccounts")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["mongodb", "mongo", "atlas", "数据库", "database"]
    )

    public static let azure = ProviderDescriptor(
        id: .azure,
        displayName: "Azure",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "与 AWS、GCP 构成公有云 IaaS 寡头，份额持续追赶第一名。",
        colorKey: "azure",
        billingURL: URL(string: "https://portal.azure.com/#view/Microsoft_Azure_GTM/ModernBillingMenuBlade")!,
        credentialSetupURL: URL(
            string: "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade"
        )!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["microsoft", "微软", "azure openai", "entra"]
    )

    public static let polar = ProviderDescriptor(
        id: .polar,
        displayName: "Polar",
        kind: .usage,
        category: .payments,
        tier: .three,
        tierReason: "面向开发者的开源 MoR 新秀，融资与团队仍处种子阶段。",
        colorKey: "polar",
        billingURL: URL(string: "https://polar.sh/dashboard")!,
        credentialSetupURL: URL(string: "https://polar.sh/settings")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["payments", "支付", "手续费", "merchant of record", "polar.sh"]
    )

    public static let heroku = ProviderDescriptor(
        id: .heroku,
        displayName: "Heroku",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "品类发明者已被 Salesforce 停掉企业新售、转入维持工程，正在被 Render/Railway 替换。",
        colorKey: "heroku",
        billingURL: URL(string: "https://dashboard.heroku.com/account/billing")!,
        credentialSetupURL: URL(string: "https://dashboard.heroku.com/account/applications")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["dyno", "salesforce", "paas", "部署"]
    )

    public static let revenuecat = ProviderDescriptor(
        id: .revenuecat,
        displayName: "RevenueCat",
        kind: .usage,
        category: .payments,
        tier: .one,
        tierReason: "移动订阅内购的基础设施默认层，约三分之一新订阅应用在用。",
        colorKey: "revenuecat",
        billingURL: URL(string: "https://app.revenuecat.com/settings/billing")!,
        credentialSetupURL: URL(string: "https://app.revenuecat.com/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["iap", "内购", "订阅", "subscription", "rc", "抽成"]
    )

    public static let gitlab = ProviderDescriptor(
        id: .gitlab,
        displayName: "GitLab",
        kind: .planAndUsage,
        category: .devTools,
        tier: .two,
        tierReason: "企业与自托管 DevSecOps 的主要替代，体量够大但远未撼动 GitHub 默认地位。",
        colorKey: "gitlab",
        billingURL: URL(string: "https://gitlab.com/-/profile/usage_quotas")!,
        credentialSetupURL: URL(string: "https://customers.gitlab.com")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["ci", "pipeline", "runner", "计算分钟", "compute minutes", "席位", "premium", "ultimate", "duo"]
    )

    public static let render = ProviderDescriptor(
        id: .render,
        displayName: "Render",
        kind: .planAndUsage,
        category: .hosting,
        tier: .two,
        tierReason: "全栈 PaaS 里团队会真正选的 Heroku 替代，开发和融资都在加速。",
        colorKey: "render",
        billingURL: URL(string: "https://dashboard.render.com/billing")!,
        credentialSetupURL: URL(string: "https://dashboard.render.com/u/settings")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["paas", "部署", "deploy", "web service"]
    )

    public static let qdrant = ProviderDescriptor(
        id: .qdrant,
        displayName: "Qdrant Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "开源向量库里增长最快的挑战者，下载与 GitHub 热度已超过 Weaviate。",
        colorKey: "qdrant",
        billingURL: URL(string: "https://cloud.qdrant.io/billing")!,
        credentialSetupURL: URL(string: "https://cloud.qdrant.io/access-management")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["vector", "向量", "embedding", "rag"]
    )

    public static let expo = ProviderDescriptor(
        id: .expo,
        displayName: "Expo EAS",
        kind: .planAndUsage,
        category: .devTools,
        tier: .one,
        tierReason: "在 React Native 云构建这一细分里已是默认流水线，EAS Build/Submit 覆盖大多数团队。",
        colorKey: "expo",
        billingURL: URL(string: "https://expo.dev/settings/billing")!,
        credentialSetupURL: URL(string: "https://expo.dev/settings/access-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["react native", "rn", "eas build", "eas update", "打包"]
    )

    public static let groq = ProviderDescriptor(
        id: .groq,
        displayName: "Groq",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "LPU 低延迟品牌仍在，但核心芯片与创始团队已被英伟达买走，现为重建中的推理云挑战者。",
        colorKey: "groq",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开文档只有控制台 Usage，没有账单金额接口。",
        searchKeywords: ["groq cloud", "llama", "inference"]
    )

    public static let together = ProviderDescriptor(
        id: .together,
        displayName: "Together AI",
        kind: .usage,
        category: .aiInference,
        tier: .one,
        tierReason: "开源模型 GPU 推理云寡头之一，年预订已过十亿美元。",
        colorKey: "together",
        billingURL: URL(string: "https://api.together.ai/settings/billing")!,
        credentialSetupURL: URL(string: "https://docs.together.ai/reference/billing-usage")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["together.ai", "togetherai", "billing usage", "USD", "metronome"]
    )

    public static let replicate = ProviderDescriptor(
        id: .replicate,
        displayName: "Replicate",
        kind: .usage,
        category: .aiInference,
        tier: .four,
        tierReason: "社区模型托管被 Cloudflare 低价收购，已失去独立地位，输给 fal 等媒体推理云。",
        colorKey: "replicate",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 OpenAPI 只有预测和部署，没有账单金额。",
        searchKeywords: ["replicate.com", "predictions"]
    )

    public static let perplexity = ProviderDescriptor(
        id: .perplexity,
        displayName: "Perplexity",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "消费级 AI 搜索的最强挑战者，搜索总盘仍由 Google 垄断。",
        colorKey: "perplexity",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "API 平台预充值只在控制台，公开接口不给余额或本月花费。",
        searchKeywords: ["sonar", "pplx", "perplexity.ai"]
    )
}
