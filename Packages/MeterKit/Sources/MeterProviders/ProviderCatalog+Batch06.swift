import Foundation
import MeterCore

extension ProviderCatalog {
    public static let postmark = ProviderDescriptor(
        id: .postmark,
        displayName: "Postmark",
        kind: .planAndUsage,
        category: .messaging,
        tier: .three,
        tierReason: "投递率领先的精品事务邮件，规模远小于 SendGrid/Mailgun。",
        colorKey: "postmark",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有发送统计，没有账单金额。",
        searchKeywords: ["postmarkapp", "email", "transactional"]
    )

    public static let sanity = ProviderDescriptor(
        id: .sanity,
        displayName: "Sanity",
        kind: .planAndUsage,
        category: .cms,
        tier: .three,
        tierReason: "无头 CMS 的高增长挑战者，客户含 Figma/Shopify，规模仍小于 Contentful。",
        colorKey: "sanity",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["sanity.io", "cms", "content"]
    )

    public static let ably = ProviderDescriptor(
        id: .ably,
        displayName: "Ably",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "实时基础设施吞吐巨大，付费客户数仍明显小于 Pusher。",
        colorKey: "ably",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有消息计数，没有账单金额。",
        searchKeywords: ["ably.com", "pubsub", "realtime"]
    )

    public static let crunchybridge = ProviderDescriptor(
        id: .crunchybridge,
        displayName: "Crunchy Bridge",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "已被 Snowflake 收编为 Snowflake Postgres，独立品牌在消退。",
        colorKey: "crunchybridge",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "发票只在控制台，没有公开账单金额接口。",
        searchKeywords: ["crunchydata", "postgres", "postgresql", "数据库"]
    )

    public static let influxdb = ProviderDescriptor(
        id: .influxdb,
        displayName: "InfluxDB Cloud",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "时序品类鼻祖热度下滑，融资停在 2023，云渠道还在退市。",
        colorKey: "influxdb",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有用量指标，没有账单金额。",
        searchKeywords: ["influxdata", "timeseries", "时序"]
    )

    public static let axiom = ProviderDescriptor(
        id: .axiom,
        displayName: "Axiom",
        kind: .usage,
        category: .observability,
        tier: .three,
        tierReason: "廉价全量事件存储的小而快玩家，尚未进入 Gartner 象限。",
        colorKey: "axiom",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有 GB 摄入，没有账单金额。",
        searchKeywords: ["axiom.co", "logs", "observability"]
    )

    public static let checkly = ProviderDescriptor(
        id: .checkly,
        displayName: "Checkly",
        kind: .planAndUsage,
        category: .ciCd,
        tier: .three,
        tierReason: "Playwright 监控即代码的开发者向合成监控有口碑，但体量远小于 Datadog/Dynatrace。",
        colorKey: "checkly",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有套餐额度，没有账单金额。",
        searchKeywords: ["checklyhq", "synthetic", "monitoring"]
    )

    public static let timescale = ProviderDescriptor(
        id: .timescale,
        displayName: "Timescale Cloud",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "已改名 Tiger Data，时序 Postgres 云用量翻倍增长，但仍远小于通用云数仓。",
        colorKey: "timescale",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["timescaledb", "postgres", "时序", "数据库"]
    )

    public static let browserstack = ProviderDescriptor(
        id: .browserstack,
        displayName: "BrowserStack",
        kind: .usage,
        category: .ciCd,
        tier: .one,
        tierReason: "云真机/跨浏览器测试的明显第一名，收入与客户数把 Sauce/LambdaTest 甩开一截。",
        colorKey: "browserstack",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["browserstack.com", "testing", "selenium"]
    )

    public static let snyk = ProviderDescriptor(
        id: .snyk,
        displayName: "Snyk",
        kind: .subscription,
        category: .ciCd,
        tier: .two,
        tierReason: "仍是独立开发者安全头部厂商且入选 Gartner 领导者，但增长失速、平台捆绑正在分流。",
        colorKey: "snyk",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["snyk.io", "security", "cve"]
    )

    public static let circleci = ProviderDescriptor(
        id: .circleci,
        displayName: "CircleCI",
        kind: .planAndUsage,
        category: .ciCd,
        tier: .four,
        tierReason: "独立 CI 被 GitHub Actions 默认化持续蚕食，份额已掉到个位数并持续下滑。",
        colorKey: "circleci",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只有 credits / 分钟，没有账单金额。",
        searchKeywords: ["circleci.com", "ci", "cd"]
    )

    public static let terraform = ProviderDescriptor(
        id: .terraform,
        displayName: "Terraform Cloud",
        kind: .usage,
        category: .dataPipeline,
        tier: .one,
        tierReason: "多云 IaC 仍是 Terraform 的安装基数垄断，尽管许可与 IBM 收购让忠诚度出现裂缝。",
        colorKey: "terraform",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["hashicorp", "hcp", "iac", "terraform.io"]
    )

    public static let tailscale = ProviderDescriptor(
        id: .tailscale,
        displayName: "Tailscale",
        kind: .subscription,
        category: .networkEdge,
        tier: .one,
        tierReason: "开发者 WireGuard 叠加组网的事实标准。",
        colorKey: "tailscale",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["tailscale.com", "wireguard", "vpn", "mesh"]
    )

    public static let deno = ProviderDescriptor(
        id: .deno,
        displayName: "Deno Deploy",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "Deno Deploy 仍是边缘 JS 利基，体量远小于 Cloudflare Workers/Vercel。",
        colorKey: "deno",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["deno.com", "deno.land", "deploy"]
    )

    public static let plausible = ProviderDescriptor(
        id: .plausible,
        displayName: "Plausible",
        kind: .subscription,
        category: .analytics,
        tier: .three,
        tierReason: "隐私优先网页分析的小而稳生意，份额远低于 GA 但高于 Fathom。",
        colorKey: "plausible",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["plausible.io", "analytics", "统计"]
    )

    public static let prefect = ProviderDescriptor(
        id: .prefect,
        displayName: "Prefect",
        kind: .usage,
        category: .dataPipeline,
        tier: .two,
        tierReason: "现代编排里最强的 Airflow 挑战者，已盈利并吞并 Dagster，正在收拢次世代品类。",
        colorKey: "prefect",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["prefect.io", "workflow", "orchestration"]
    )

    public static let airbyte = ProviderDescriptor(
        id: .airbyte,
        displayName: "Airbyte",
        kind: .usage,
        category: .dataPipeline,
        tier: .two,
        tierReason: "开源 ELT 的第一挑战者，连接器与社区足以紧跟 Fivetran，但付费规模仍小一个数量级。",
        colorKey: "airbyte",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["airbyte.com", "elt", "etl"]
    )

    public static let exoscale = ProviderDescriptor(
        id: .exoscale,
        displayName: "Exoscale",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "瑞士/欧洲合规向小云，产品还在，但全球 VPS 份额可忽略。",
        colorKey: "exoscale",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "用量接口只给小时和 GiB.h，没有账单金额。",
        searchKeywords: ["exoscale.com", "cloudstack"]
    )

    public static let vonage = ProviderDescriptor(
        id: .vonage,
        displayName: "Vonage",
        kind: .prepaid,
        category: .messaging,
        tier: .two,
        tierReason: "重返 Gartner 领导者，体量仍次于 Twilio、Infobip 和 Sinch。",
        colorKey: "vonage",
        billingURL: URL(string: "https://dashboard.nexmo.com")!,
        credentialSetupURL: URL(string: "https://dashboard.nexmo.com/settings")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["nexmo", "vonage.com", "sms", "voice"]
    )

    public static let plivo = ProviderDescriptor(
        id: .plivo,
        displayName: "Plivo",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "低价 Twilio 替代且已盈利，尚未进入 CPaaS 前十。",
        colorKey: "plivo",
        billingURL: URL(string: "https://console.plivo.com")!,
        credentialSetupURL: URL(string: "https://console.plivo.com/dashboard/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["plivo.com", "sms", "voice"]
    )

    public static let messagebird = ProviderDescriptor(
        id: .messagebird,
        displayName: "MessageBird",
        kind: .prepaid,
        category: .messaging,
        tier: .four,
        tierReason: "已退出领导者阵营，员工大幅收缩，正在萎缩。",
        colorKey: "messagebird",
        billingURL: URL(string: "https://dashboard.messagebird.com")!,
        credentialSetupURL: URL(string: "https://dashboard.messagebird.com/en/developers/access")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["messagebird.com", "bird.com", "sms"]
    )

    public static let ibm = ProviderDescriptor(
        id: .ibm,
        displayName: "IBM Cloud",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "IaaS 收入基本停滞、份额掉到约 1%，公司已转向红帽混合云而非公有云抢量。",
        colorKey: "ibm",
        billingURL: URL(string: "https://cloud.ibm.com/billing")!,
        credentialSetupURL: URL(string: "https://cloud.ibm.com/iam/apikeys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["ibmcloud", "bluemix", "softlayer"]
    )

    public static let brevo = ProviderDescriptor(
        id: .brevo,
        displayName: "Brevo",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "中小企业邮件营销第二梯队，正在快速抢份额。",
        colorKey: "brevo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开接口只给发送 credits，不是账单金额。",
        searchKeywords: ["sendinblue", "brevo.com", "email"]
    )

    public static let redpanda = ProviderDescriptor(
        id: .redpanda,
        displayName: "Redpanda Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "Kafka 协议性能派挑战者已成独角兽，对 Confluent/MSK 构成实质分流。",
        colorKey: "redpanda",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单只在控制台和 CSV，没有公开账单金额接口。",
        searchKeywords: ["redpanda.com", "kafka"]
    )

    public static let fauna = ProviderDescriptor(
        id: .fauna,
        displayName: "Fauna",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "托管服务已于 2025 年关停，属于明确退出市场。",
        colorKey: "fauna",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["fauna.com", "fql", "数据库"]
    )

    public static let kamatera = ProviderDescriptor(
        id: .kamatera,
        displayName: "Kamatera",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "多区域灵活 VPS 的小型供应商，报告里有名但无公开量级，属于持续存在的长尾。",
        colorKey: "kamatera",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["kamatera.com", "vps"]
    )

    public static let onesignal = ProviderDescriptor(
        id: .onesignal,
        displayName: "OneSignal",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "独立推送 SaaS 的领先挑战者，Shopify 渠道则在退。",
        colorKey: "onesignal",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["onesignal.com", "push", "notification"]
    )
}
