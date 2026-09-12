import Foundation
import MeterCore

extension ProviderCatalog {
    public static let cloudflare = ProviderDescriptor(
        id: .cloudflare,
        displayName: "Cloudflare",
        kind: .usage,
        category: .networkEdge,
        tier: .one,
        tierReason: "网站反向代理近乎垄断，安全加边缘收入高速增长。",
        colorKey: "cloudflare",
        billingURL: URL(string: "https://dash.cloudflare.com/?to=/:account/billing")!,
        credentialSetupURL: URL(string: "https://dash.cloudflare.com/profile/api-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["cf", "workers", "r2", "d1", "pages", "云"],
        guideURLs: [
            "findAccountAndZoneIDs": URL(
                string: "https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/"
            )!,
        ]
    )

    public static let neon = ProviderDescriptor(
        id: .neon,
        displayName: "Neon",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "无服务器 Postgres 的领先独立选手，被 Databricks 收购后并入 Lakebase，产品仍在加注。",
        colorKey: "neon",
        billingURL: URL(string: "https://console.neon.tech/app/billing")!,
        credentialSetupURL: URL(string: "https://console.neon.tech/app/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["postgres", "postgresql", "database", "数据库"]
    )

    public static let aws = ProviderDescriptor(
        id: .aws,
        displayName: "AWS",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "全球 IaaS 仍由 AWS、Azure、GCP 三分，AWS 份额虽缓降但仍是第一名。",
        colorKey: "aws",
        billingURL: URL(string: "https://console.aws.amazon.com/costmanagement/home")!,
        credentialSetupURL: URL(string: "https://console.aws.amazon.com/iamv2/home#/users/create")!,
        costsMoneyToRefresh: true,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["amazon", "amazon web services", "s3", "ec2", "lambda", "bedrock", "亚马逊"]
    )

    public static let openai = ProviderDescriptor(
        id: .openai,
        displayName: "OpenAI",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "与 Anthropic、Google 三分企业 LLM 支出，消费端聊天仍过半，是前沿 API 寡头之一。",
        colorKey: "openai",
        billingURL: URL(string: "https://platform.openai.com/settings/organization/billing/overview")!,
        credentialSetupURL: URL(string: "https://platform.openai.com/settings/organization/admin-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["chatgpt", "gpt", "dall-e", "sora", "开放 AI"]
    )

    public static let anthropic = ProviderDescriptor(
        id: .anthropic,
        displayName: "Anthropic",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "企业 API 支出与编程场景的领先者，和 OpenAI、Google 构成支出寡头。",
        colorKey: "anthropic",
        billingURL: URL(string: "https://console.anthropic.com/settings/billing")!,
        credentialSetupURL: URL(string: "https://console.anthropic.com/settings/admin-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["claude", "claude code", "sonnet", "opus", "克劳德"]
    )

    public static let vercel = ProviderDescriptor(
        id: .vercel,
        displayName: "Vercel",
        // Hobby 没有发票，charges 404 记用量 $0；Pro 有 BilledCost 才是真正的钱。
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "前端/应用托管（尤其 Next.js）已由 Vercel 以数量级优势领跑，Netlify 等被拉开。",
        colorKey: "vercel",
        billingURL: URL(string: "https://vercel.com/account/billing")!,
        credentialSetupURL: URL(string: "https://vercel.com/account/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 11,
        accessStatus: .pendingVerification,
        searchKeywords: ["next", "nextjs", "next.js"]
    )

    public static let github = ProviderDescriptor(
        id: .github,
        displayName: "GitHub",
        // Actions 分钟是从量；Copilot 月费走 usage 里 unitType=month 那一行。暂时按月费加超额。
        kind: .planAndUsage,
        category: .devTools,
        tier: .one,
        tierReason: "代码托管已成事实标准，Actions 与 Copilot 把 CI 和 AI 一并锁进同一平台。",
        colorKey: "github",
        billingURL: URL(string: "https://github.com/settings/billing")!,
        credentialSetupURL: URL(string: "https://github.com/settings/personal-access-tokens/new?expires_in=none&plan=read")!,
        costsMoneyToRefresh: false,
        // usageItems 每条都带 date，`dailyUSD` 一直是按天填的。
        supportsDailyGranularity: true,
        // 这条接口一次只吃一个 year/month，历史靠逐月请求，见 GitHubBillingProvider。
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["copilot", "actions", "gh", "微软"]
    )

    public static let fly = ProviderDescriptor(
        id: .fly,
        displayName: "Fly.io",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "全球边缘/Machines 仍是 Render/Railway 并列短名单，虽停 GPU 但宿主平台还在加注。",
        colorKey: "fly",
        billingURL: URL(string: "https://fly.io/dashboard/personal/billing")!,
        credentialSetupURL: URL(string: "https://fly.io/dashboard/personal/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["fly.io", "flyio", "machines"]
    )

    public static let openrouter = ProviderDescriptor(
        id: .openrouter,
        displayName: "OpenRouter",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "独立多模型路由的事实标准，流量与收购估值都远超其他聚合器。",
        colorKey: "openrouter",
        billingURL: URL(string: "https://openrouter.ai/settings/credits")!,
        credentialSetupURL: URL(string: "https://openrouter.ai/settings/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .available,
        searchKeywords: ["open router", "or", "聚合"]
    )

    public static let deepseek = ProviderDescriptor(
        id: .deepseek,
        displayName: "DeepSeek",
        kind: .prepaid,
        category: .aiInference,
        tier: .one,
        tierReason: "公共网关 token 量与 OpenAI 并列第一梯队，是全球廉价前沿 API 的默认选项。",
        colorKey: "deepseek",
        billingURL: URL(string: "https://platform.deepseek.com/top_up")!,
        credentialSetupURL: URL(string: "https://platform.deepseek.com/api_keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .available,
        searchKeywords: ["深度求索", "ds"]
    )

    public static let moonshot = ProviderDescriptor(
        id: .moonshot,
        // 和旁边那家同一品牌、两套 API。月之暗面 / Kimi 只当搜索别名。
        displayName: "Moonshot (China)",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "Kimi 在质量与溢价支出上是中国头部挑战者，商业化与港股冲刺并行。",
        colorKey: "moonshot",
        billingURL: URL(string: "https://platform.kimi.com/console/pay")!,
        credentialSetupURL: URL(string: "https://platform.kimi.com/console/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .available,
        searchKeywords: ["kimi", "moonshot", "kimi.ai", "国内", "月之暗面", "china"]
    )

    public static let moonshotAI = ProviderDescriptor(
        id: .moonshotAI,
        displayName: "Moonshot (Overseas)",
        kind: .prepaid,
        category: .aiInference,
        tier: .two,
        tierReason: "与国内月之暗面同一公司的海外 API，质量与溢价定位同属中国头部挑战者。",
        colorKey: "moonshotai",
        billingURL: URL(string: "https://platform.moonshot.ai/console/pay")!,
        credentialSetupURL: URL(string: "https://platform.moonshot.ai/console/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["kimi", "moonshot ai", "moonshot.ai", "海外", "国际", "oversea", "overseas"]
    )

    public static let xai = ProviderDescriptor(
        id: .xai,
        displayName: "xAI",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "Grok 消费端与算力规模已是强挑战者，但公共 API 份额仍远低于三巨头与 DeepSeek。",
        colorKey: "xai",
        billingURL: URL(string: "https://console.x.ai/team/default/billing")!,
        credentialSetupURL: URL(string: "https://console.x.ai/team/default/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["grok", "x.ai", "spacexai", "supergrok", "grok.com"]
    )

    public static let cursor = ProviderDescriptor(
        id: .cursor,
        displayName: "Cursor",
        kind: .subscription,
        category: .aiInference,
        tier: .one,
        tierReason: "独立 AI IDE 的绝对龙头，收入与企业采购占有率碾压 Windsurf 等同类。",
        colorKey: "cursor",
        billingURL: URL(string: "https://cursor.com/dashboard/billing")!,
        credentialSetupURL: URL(string: "https://cursor.com/docs/models-and-pricing")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["cursor ai", "cursor.sh", "anysphere", "ide", "编辑器"]
    )

    public static let digitalocean = ProviderDescriptor(
        id: .digitalocean,
        displayName: "DigitalOcean",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "独立开发者云/VPS 的首选替代，收入已破十亿美元量级且 AI 客户在加速。",
        colorKey: "digitalocean",
        billingURL: URL(string: "https://cloud.digitalocean.com/account/billing")!,
        credentialSetupURL: URL(string: "https://cloud.digitalocean.com/account/api/tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["do", "droplet", "数字海洋"]
    )

    public static let twilio = ProviderDescriptor(
        id: .twilio,
        displayName: "Twilio",
        kind: .usage,
        category: .messaging,
        tier: .one,
        tierReason: "全球 CPaaS 收入份额第一，与 Infobip、Sinch 构成寡头。",
        colorKey: "twilio",
        billingURL: URL(string: "https://1console.twilio.com/go?to=/billing")!,
        credentialSetupURL: URL(string: "https://1console.twilio.com/go?to=/account/__account__/settings/us1/api-keys/list")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .available,
        searchKeywords: ["sms", "whatsapp", "语音"],
        guideURLs: [
            "accountSettings": URL(
                string: "https://1console.twilio.com/go?to=/account/__account__/settings"
            )!,
        ]
    )

    public static let planetscale = ProviderDescriptor(
        id: .planetscale,
        displayName: "PlanetScale",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "Vitess 系 MySQL 水平扩展的企业级挑战者，推出 Postgres 后收入明显回升。",
        colorKey: "planetscale",
        billingURL: URL(string: "https://app.planetscale.com")!,
        credentialSetupURL: URL(string: "https://app.planetscale.com/settings/service-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["mysql", "vitess", "pscale"]
    )

    public static let upstash = ProviderDescriptor(
        id: .upstash,
        displayName: "Upstash",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "面向 Serverless/Edge 的 Redis/KV 小而活跃，资金与体量远小于 Redis 本体与云厂商。",
        colorKey: "upstash",
        billingURL: URL(string: "https://console.upstash.com/account/billing")!,
        credentialSetupURL: URL(string: "https://console.upstash.com/account/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["redis", "qstash", "vector"]
    )

    public static let elevenlabs = ProviderDescriptor(
        id: .elevenlabs,
        displayName: "ElevenLabs",
        kind: .freeTier,
        category: .aiInference,
        tier: .one,
        tierReason: "独立 TTS/语音平台的绝对龙头，收入与开发者规模碾压 Cartesia 等。",
        colorKey: "elevenlabs",
        billingURL: URL(string: "https://elevenlabs.io/app/subscription")!,
        credentialSetupURL: URL(string: "https://elevenlabs.io/app/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["eleven", "tts", "语音", "voice"]
    )
}
