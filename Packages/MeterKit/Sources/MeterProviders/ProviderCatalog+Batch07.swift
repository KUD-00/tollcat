import Foundation
import MeterCore

extension ProviderCatalog {
    public static let courier = ProviderDescriptor(
        id: .courier,
        displayName: "Courier",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "通知编排层仍小，融资停留在 2022 年 B 轮。",
        colorKey: "courier",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["courier.com", "notification"]
    )

    public static let doppler = ProviderDescriptor(
        id: .doppler,
        displayName: "Doppler",
        kind: .subscription,
        category: .authSecurity,
        tier: .three,
        tierReason: "开发者密钥 SaaS 的早期品牌，融资停在 2022 年 Series A，规模远小于 Vault。",
        colorKey: "doppler",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["doppler.com", "secrets"]
    )

    public static let infisical = ProviderDescriptor(
        id: .infisical,
        displayName: "Infisical",
        kind: .subscription,
        category: .authSecurity,
        tier: .three,
        tierReason: "开源密钥管理的高增长挑战者，正在从 Doppler/Vault 抢开发者。",
        colorKey: "infisical",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["infisical.com", "secrets"]
    )

    public static let kinsta = ProviderDescriptor(
        id: .kinsta,
        displayName: "Kinsta",
        kind: .planAndUsage,
        category: .hosting,
        tier: .two,
        tierReason: "高端托管 WordPress 里与 WP Engine 并列被点名的选项，客户数仍在快增。",
        colorKey: "kinsta",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["kinsta.com", "wordpress", "hosting"]
    )

    public static let imgix = ProviderDescriptor(
        id: .imgix,
        displayName: "imgix",
        kind: .usage,
        category: .media,
        tier: .three,
        tierReason: "实时图片 CDN 次于 Cloudinary，体量小且已转向积分计价。",
        colorKey: "imgix",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["imgix.com", "cdn", "image"]
    )

    public static let fathom = ProviderDescriptor(
        id: .fathom,
        displayName: "Fathom",
        kind: .subscription,
        category: .analytics,
        tier: .three,
        tierReason: "同样走无 Cookie 网页分析，站点规模约为 Plausible 的一半。",
        colorKey: "fathom",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["usefathom", "analytics", "统计"]
    )

    public static let mailchimp = ProviderDescriptor(
        id: .mailchimp,
        displayName: "Mailchimp",
        kind: .usage,
        category: .messaging,
        tier: .one,
        tierReason: "安装基数仍近半壁江山，虽增长停滞但仍是邮件营销寡头。",
        colorKey: "mailchimp",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["mailchimp.com", "email", "intuit"]
    )

    public static let klaviyo = ProviderDescriptor(
        id: .klaviyo,
        displayName: "Klaviyo",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "电商 CRM 与 Shopify 邮件的强挑战者，收入仍在高速扩张。",
        colorKey: "klaviyo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["klaviyo.com", "email"]
    )

    public static let bitbucket = ProviderDescriptor(
        id: .bitbucket,
        displayName: "Bitbucket",
        kind: .subscription,
        category: .devTools,
        tier: .four,
        tierReason: "份额远落后于 GitHub/GitLab，基本靠 Atlassian 套件续命，独立代码托管心智在收缩。",
        colorKey: "bitbucket",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["bitbucket.org", "atlassian", "git"]
    )

    public static let buildkite = ProviderDescriptor(
        id: .buildkite,
        displayName: "Buildkite",
        kind: .usage,
        category: .ciCd,
        tier: .three,
        tierReason: "份额很小，但混合自建 runner 在超大规模工程组织里有稳固高端阵地。",
        colorKey: "buildkite",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["buildkite.com", "ci", "cd"]
    )

    public static let codecov = ProviderDescriptor(
        id: .codecov,
        displayName: "Codecov",
        kind: .subscription,
        category: .ciCd,
        tier: .two,
        tierReason: "托管覆盖率报告的事实默认项，但已两次被收购，正变成交付平台里的功能模块。",
        colorKey: "codecov",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["codecov.io", "coverage"]
    )

    public static let sonarcloud = ProviderDescriptor(
        id: .sonarcloud,
        displayName: "SonarCloud",
        kind: .planAndUsage,
        category: .ciCd,
        tier: .one,
        tierReason: "静态分析/代码质量几乎由 Sonar 一家定义，云端 SonarCloud 是同一垄断品牌的 SaaS 面。",
        colorKey: "sonarcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["sonarcloud.io", "sonarqube", "quality"]
    )

    public static let fivetran = ProviderDescriptor(
        id: .fivetran,
        displayName: "Fivetran",
        kind: .usage,
        category: .dataPipeline,
        tier: .one,
        tierReason: "托管数据接入的企业默认层，与 dbt 合并后把 EL+T 收成同一寡头。",
        colorKey: "fivetran",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["fivetran.com", "elt", "etl"]
    )

    public static let clicksend = ProviderDescriptor(
        id: .clicksend,
        displayName: "ClickSend",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "按量计费的中小企业多通道短信，未进入分析师前十。",
        colorKey: "clicksend",
        billingURL: URL(string: "https://dashboard.clicksend.com")!,
        credentialSetupURL: URL(string: "https://developers.clicksend.com/docs")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["clicksend.com", "sms", "fax"]
    )

    public static let infobip = ProviderDescriptor(
        id: .infobip,
        displayName: "Infobip",
        kind: .prepaid,
        category: .messaging,
        tier: .one,
        tierReason: "与 Twilio 并列 CPaaS 领导者，愿景轴略占优。",
        colorKey: "infobip",
        billingURL: URL(string: "https://portal.infobip.com")!,
        credentialSetupURL: URL(
            string: "https://www.infobip.com/docs/essentials/api-authentication"
        )!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["infobip.com", "sms", "cpaas"]
    )

    public static let textmagic = ProviderDescriptor(
        id: .textmagic,
        displayName: "Textmagic",
        kind: .prepaid,
        category: .messaging,
        tier: .four,
        tierReason: "传统按量短信工具，正被销售向 SMS 套件替代。",
        colorKey: "textmagic",
        billingURL: URL(string: "https://app.textmagic.com")!,
        credentialSetupURL: URL(string: "https://app.textmagic.com/settings/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["textmagic.com", "sms"]
    )

    public static let sinch = ProviderDescriptor(
        id: .sinch,
        displayName: "Sinch",
        kind: .usage,
        category: .messaging,
        tier: .one,
        tierReason: "CPaaS 份额第二梯队寡头，与 Twilio、Infobip 几分天下。",
        colorKey: "sinch",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "官方声明没有 Billing API，账单只在控制台。",
        searchKeywords: ["sinch.com", "sms", "voice"]
    )

    public static let smtp2go = ProviderDescriptor(
        id: .smtp2go,
        displayName: "SMTP2GO",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "投递测试领先的小型 SMTP，发送量不在第一档。",
        colorKey: "smtp2go",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有发送配额，没有账单金额。",
        searchKeywords: ["smtp2go.com", "email"]
    )

    public static let mailjet = ProviderDescriptor(
        id: .mailjet,
        displayName: "Mailjet",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "Sinch 旗下欧盟邮件品牌，发送量远小于同胞 Mailgun。",
        colorKey: "mailjet",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 只有资料和发送统计，没有账单金额。",
        searchKeywords: ["mailjet.com", "email"]
    )

    public static let n8n = ProviderDescriptor(
        id: .n8n,
        displayName: "n8n Cloud",
        kind: .subscription,
        category: .automation,
        tier: .two,
        tierReason: "开源工作流自动化的强挑战者，一年内冲到亿美元 ARR 并拿到 SAP 战略入股。",
        colorKey: "n8n",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "n8n Cloud 没有公开账单金额接口。",
        searchKeywords: ["n8n.io", "workflow", "automation"]
    )

    public static let hasura = ProviderDescriptor(
        id: .hasura,
        displayName: "Hasura",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "GraphQL 自动 API 红利消退，2022 年后未再融资并转向 PromptQL 咨询。",
        colorKey: "hasura",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单只在控制台，没有公开账单金额接口。",
        searchKeywords: ["hasura.io", "graphql"]
    )

    public static let elks = ProviderDescriptor(
        id: .elks,
        displayName: "46elks",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "北欧自助短信/语音 API，区域利基且仍被列为欧洲替代。",
        colorKey: "elks",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "官方 GET /a1/me 的 balance 是未写清单位的整数，不能自行折钱。",
        searchKeywords: ["46elks", "elks", "sms"]
    )

    public static let keycdn = ProviderDescriptor(
        id: .keycdn,
        displayName: "KeyCDN",
        kind: .usage,
        category: .networkEdge,
        tier: .four,
        tierReason: "长尾廉价 CDN，站点份额约 0.1% 且无扩张信号。",
        colorKey: "keycdn",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开报表是流量字节和 credit 流水，没有一份本月应付合计。",
        searchKeywords: ["keycdn.com", "cdn"]
    )

    public static let cdn77 = ProviderDescriptor(
        id: .cdn77,
        displayName: "CDN77",
        kind: .prepaid,
        category: .networkEdge,
        tier: .three,
        tierReason: "媒体 CDN 收入过两亿美元且现金流转正，仍远小于三巨头。",
        colorKey: "cdn77",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "credit-balance 没写货币，不能当美元用。",
        searchKeywords: ["cdn77.com", "cdn"]
    )

    public static let astra = ProviderDescriptor(
        id: .astra,
        displayName: "DataStax Astra",
        kind: .usage,
        category: .database,
        tier: .four,
        tierReason: "Cassandra 托管已被 IBM 吞并，宽列库热度相对 DynamoDB 等持续走弱。",
        colorKey: "astra",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "DevOps 账单是企业 consumption 报表，普通组织没有一份可读的本月账单。",
        searchKeywords: ["datastax", "astra", "cassandra"]
    )

    public static let dagster = ProviderDescriptor(
        id: .dagster,
        displayName: "Dagster Cloud",
        kind: .usage,
        category: .dataPipeline,
        tier: .three,
        tierReason: "资产导向编排在现代数据团队中增长快，但份额小于 Prefect，且 2026 年已被收购。",
        colorKey: "dagster",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["dagster.io", "orchestrat"]
    )

    public static let dbt = ProviderDescriptor(
        id: .dbt,
        displayName: "dbt Cloud",
        kind: .usage,
        category: .dataPipeline,
        tier: .one,
        tierReason: "仓内 SQL 转换近乎垄断，分析工程师岗位与现代数据栈都围着 dbt 转。",
        colorKey: "dbt",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开账单金额接口。",
        searchKeywords: ["getdbt", "dbt.com", "analytics"]
    )

    public static let pulumi = ProviderDescriptor(
        id: .pulumi,
        displayName: "Pulumi Cloud",
        kind: .usage,
        category: .dataPipeline,
        tier: .two,
        tierReason: "用通用语言写 IaC 的主挑战者，客户与增速都在抬升，但仍远小于 Terraform 生态。",
        colorKey: "pulumi",
        billingURL: URL(string: "https://app.pulumi.com")!,
        credentialSetupURL: URL(string: "https://www.pulumi.com/docs/pulumi-cloud/access-management/access-tokens/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        supportsInboxIngest: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["pulumi.com", "iac"]
    )
}
