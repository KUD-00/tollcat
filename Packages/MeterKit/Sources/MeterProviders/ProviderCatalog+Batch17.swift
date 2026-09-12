import Foundation
import MeterCore

extension ProviderCatalog {
    public static let azion = ProviderDescriptor(
        id: .azion,
        displayName: "Azion",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "拉美边缘/CDN 的区域挑战者。",
        colorKey: "azion",
        billingURL: URL(string: "https://console.azion.com/billing")!,
        credentialSetupURL: URL(string: "https://www.azion.com/en/documentation/devtools/graphql-api/first-steps/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["azion", "azion.com", "edge", "cdn brazil"]
    )
    public static let elastx = ProviderDescriptor(
        id: .elastx,
        displayName: "Elastx",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "瑞典本地云的区域选手。",
        colorKey: "elastx",
        billingURL: URL(string: "https://ops.elastx.cloud/")!,
        credentialSetupURL: URL(string: "https://docs.elastx.cloud/docs/openstack-iaas/guides/billing/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["elastx", "elastx.se", "cloudkitty", "openstack sweden", "sek"]
    )


    public static let warpstream = ProviderDescriptor(
        id: .warpstream,
        displayName: "WarpStream",
        kind: .usage,
        category: .database,
        tier: .three,
        tierReason: "无磁盘 Kafka 兼容新秀，体量仍小。",
        colorKey: "warpstream",
        billingURL: URL(string: "https://console.warpstream.com/")!,
        credentialSetupURL: URL(string: "https://docs.warpstream.com/warpstream/reference/api-reference/invoices/get-pending-invoice")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["warpstream", "kafka", "byoc", "streaming"]
    )

    public static let neo4j = ProviderDescriptor(
        id: .neo4j,
        displayName: "Neo4j Aura",
        kind: .usage,
        category: .database,
        tier: .one,
        tierReason: "图数据库品类的事实标准，Aura 托管份额领先。",
        colorKey: "neo4j",
        billingURL: URL(string: "https://console.neo4j.io/")!,
        credentialSetupURL: URL(string: "https://console.neo4j.io/account/client-credentials")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        minimumRefreshInterval: 86400,
        accessStatus: .pendingVerification,
        searchKeywords: ["neo4j", "aura", "graph", "acu", "cypher"]
    )

    public static let digicert = ProviderDescriptor(
        id: .digicert,
        displayName: "DigiCert",
        kind: .usage,
        category: .authSecurity,
        tier: .one,
        tierReason: "公共信任 TLS 证书市场的寡头之一。",
        colorKey: "digicert",
        billingURL: URL(string: "https://www.digicert.com/account/")!,
        credentialSetupURL: URL(string: "https://dev.digicert.com/certcentral-apis/services-api/finance/view-balance.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["digicert", "certcentral", "ssl", "tls", "certificate"]
    )

    public static let deel = ProviderDescriptor(
        id: .deel,
        displayName: "Deel",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "全球雇佣/薪资合规的龙头挑战者，EOR 赛道份额领先。",
        colorKey: "deel",
        billingURL: URL(string: "https://app.deel.com")!,
        credentialSetupURL: URL(string: "https://developer.deel.com")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["deel.com", "letsdeel", "invoices", "platform fee"]
    )

    public static let remote = ProviderDescriptor(
        id: .remote,
        displayName: "Remote",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "全球雇佣平台的强挑战者，与 Deel 争夺中大客户。",
        colorKey: "remote",
        billingURL: URL(string: "https://employ.remote.com")!,
        credentialSetupURL: URL(string: "https://developer.remote.com/docs/pull-eor-cost-breakdown")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["remote.com", "eor", "peo", "billing-documents"]
    )

    public static let oyster = ProviderDescriptor(
        id: .oyster,
        displayName: "Oyster",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "全球雇佣平台里规模较小但仍在增长的选手。",
        colorKey: "oyster",
        billingURL: URL(string: "https://app.oysterhr.com")!,
        credentialSetupURL: URL(string: "https://docs.oysterhr.com/docs/invoicing-at-oyster")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["oysterhr", "oyster", "scale", "contractor fees"]
    )

    public static let outscale = ProviderDescriptor(
        id: .outscale,
        displayName: "3DS OUTSCALE",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "法国主权云挑战者，份额远小于三巨头。",
        colorKey: "outscale",
        billingURL: URL(string: "https://cockpit.outscale.com")!,
        credentialSetupURL: URL(string: "https://docs.outscale.com/en/userguide/Getting-Information-About-Your-Resource-Consumption.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["outscale", "3ds", "secnumcloud", "tinaos", "ReadConsumptionAccount"]
    )

    public static let orangecloud = ProviderDescriptor(
        id: .orangecloud,
        displayName: "Orange Cloud Avenue",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "法国运营商云的区域选手。",
        colorKey: "orangecloud",
        billingURL: URL(string: "https://cloud.orange-business.com")!,
        credentialSetupURL: URL(string: "https://cloud.orange-business.com/wp-content/uploads/2022/11/orange-api-v9-en.pdf")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["orange", "flexible engine", "cloud avenue", "documents", "eccs"]
    )

    public static let gridscale = ProviderDescriptor(
        id: .gridscale,
        displayName: "gridscale",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "德国中小企业云的区域选手。",
        colorKey: "gridscale",
        billingURL: URL(string: "https://my.gridscale.io")!,
        credentialSetupURL: URL(string: "https://gridscale.io/en/api-documentation/index.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["gridscale", "current_price", "iaas"]
    )

    public static let rackspace = ProviderDescriptor(
        id: .rackspace,
        displayName: "Rackspace",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "托管云老将，公有云转型后份额持续下滑。",
        colorKey: "rackspace",
        billingURL: URL(string: "https://accounts.rackspace.com")!,
        credentialSetupURL: URL(string: "https://docs.rackspace.com/reference/billing-apiguide-v2")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["rackspace", "estimated_charges", "billing api"]
    )

    public static let pika = ProviderDescriptor(
        id: .pika,
        displayName: "Pika",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "AI 视频生成 API 细分里的小型挑战者。",
        colorKey: "pika",
        billingURL: URL(string: "https://dev.pika.art")!,
        credentialSetupURL: URL(string: "https://dev.pika.art/openapi.json")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 3,
        accessStatus: .pendingVerification,
        searchKeywords: ["pika", "pika.art", "video", "spend/daily"]
    )

    public static let hedra = ProviderDescriptor(
        id: .hedra,
        displayName: "Hedra",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "AI 视频/口型驱动细分里的新秀。",
        colorKey: "hedra",
        billingURL: URL(string: "https://www.hedra.com")!,
        credentialSetupURL: URL(string: "https://www.hedra.com/docs/api-reference/v3/billing/get-usage")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 3,
        accessStatus: .pendingVerification,
        searchKeywords: ["hedra", "avatar", "video", "usage"]
    )

    public static let tidbcloud = ProviderDescriptor(
        id: .tidbcloud,
        displayName: "TiDB Cloud",
        kind: .usage,
        category: .database,
        tier: .two,
        tierReason: "分布式 HTAP 数据库云的强挑战者。",
        colorKey: "tidbcloud",
        billingURL: URL(string: "https://tidbcloud.com")!,
        credentialSetupURL: URL(string: "https://docs.pingcap.com/tidbcloud/api/v1beta1/billing/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 6,
        accessStatus: .pendingVerification,
        searchKeywords: ["tidb", "pingcap", "bills", "digest"]
    )

    public static let hyperstack = ProviderDescriptor(
        id: .hyperstack,
        displayName: "Hyperstack",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "GPU 云算力的中小型选手。",
        colorKey: "hyperstack",
        billingURL: URL(string: "https://console.hyperstack.cloud")!,
        credentialSetupURL: URL(string: "https://docs.hyperstack.cloud/docs/api-reference/get-last-day-cost")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 3,
        accessStatus: .pendingVerification,
        searchKeywords: ["hyperstack", "nexgen", "gpu", "incurred_bill", "last-day-cost"]
    )

    public static let hostup = ProviderDescriptor(
        id: .hostup,
        displayName: "HostUp",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "瑞典主机/VPS 的区域选手。",
        colorKey: "hostup",
        billingURL: URL(string: "https://cloud.hostup.se")!,
        credentialSetupURL: URL(string: "https://developer.hostup.se/endpoints/billing/get-v2-billing-invoices-id")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["hostup", "hostup.se", "invoices", "payg", "sek"]
    )

    public static let memset = ProviderDescriptor(
        id: .memset,
        displayName: "Memset",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "英国托管老将，独立品牌声量走弱。",
        colorKey: "memset",
        billingURL: URL(string: "https://www.memset.com/control/")!,
        credentialSetupURL: URL(string: "https://www.memset.com/apidocs/methods_invoice.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["memset", "invoice.list", "gbp"]
    )

    public static let mittwald = ProviderDescriptor(
        id: .mittwald,
        displayName: "mittwald",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "德国主机与应用托管的区域选手。",
        colorKey: "mittwald",
        billingURL: URL(string: "https://my.mittwald.de")!,
        credentialSetupURL: URL(string: "https://developer.mittwald.de/docs/v2/reference/contract/invoice-detail/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["mittwald", "totalGross", "invoices"]
    )

    public static let soracom = ProviderDescriptor(
        id: .soracom,
        displayName: "Soracom",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "物联网蜂窝连接平台的强挑战者，日美市场渗透高。",
        colorKey: "soracom",
        billingURL: URL(string: "https://console.soracom.io")!,
        credentialSetupURL: URL(string: "https://developers.soracom.io/en/docs/account/billing/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 18,
        accessStatus: .pendingVerification,
        searchKeywords: ["soracom", "iot", "sim", "bills", "jpy", "dailybill"]
    )

    public static let starlink = ProviderDescriptor(
        id: .starlink,
        displayName: "Starlink",
        kind: .usage,
        category: .networkEdge,
        tier: .one,
        tierReason: "低轨卫星宽带几乎垄断可规模采购的企业选项。",
        colorKey: "starlink",
        billingURL: URL(string: "https://www.starlink.com/account")!,
        credentialSetupURL: URL(string: "https://starlink.readme.io/reference/get_public-v2-billing-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["starlink", "spacex", "invoices", "iso4217"]
    )

    public static let tibber = ProviderDescriptor(
        id: .tibber,
        displayName: "Tibber",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "北欧电力零售/智能用电的强挑战者。",
        colorKey: "tibber",
        billingURL: URL(string: "https://tibber.com")!,
        credentialSetupURL: URL(string: "https://developer.tibber.com/docs/overview")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["tibber", "electricity", "consumption", "graphql", "nordic"]
    )

    public static let once = ProviderDescriptor(
        id: .once,
        displayName: "1NCE",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "物联网蜂窝（1NCE）低价长周期卡的强挑战者。",
        colorKey: "once",
        billingURL: URL(string: "https://portal.1nce.com")!,
        credentialSetupURL: URL(string: "https://help.1nce.com/api/order-management/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["1nce", "once", "iot", "sim", "orders", "invoice_amount"]
    )

    public static let octopusenergy = ProviderDescriptor(
        id: .octopusenergy,
        displayName: "Octopus Energy",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "英国与多国电力零售的强挑战者，API 与智能电表渗透高。",
        colorKey: "octopusenergy",
        billingURL: URL(string: "https://octopus.energy")!,
        credentialSetupURL: URL(string: "https://developer.octopus.energy/graphql/reference/objects/costofusageperiod/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["octopus", "kraken", "costOfUsage", "EstimatedMoneyType", "electricity"]
    )

    public static let pge = ProviderDescriptor(
        id: .pge,
        displayName: "PG&E",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "加州电网公用事业的区域垄断运营商。",
        colorKey: "pge",
        billingURL: URL(string: "https://www.pge.com")!,
        credentialSetupURL: URL(string: "https://www.pge.com/assets/pge/docs/save-energy-and-money/energy-savings-programs/Supported-Data-Elements.pdf")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["pge", "share my data", "green button", "espi", "billLastPeriod"]
    )

    public static let coned = ProviderDescriptor(
        id: .coned,
        displayName: "Con Edison",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "纽约都会区电力公用事业的区域垄断运营商。",
        colorKey: "coned",
        billingURL: URL(string: "https://www.coned.com")!,
        credentialSetupURL: URL(string: "https://www.coned.com/-/media/files/coned/documents/accountandbilling/share-my-data/onboarding-doc.pdf")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["coned", "con edison", "oru", "share my data", "green button", "billLastPeriod", "espi"]
    )

    public static let dynatrace = ProviderDescriptor(
        id: .dynatrace,
        displayName: "Dynatrace",
        kind: .usage,
        category: .observability,
        tier: .one,
        tierReason: "企业 APM/可观测性的寡头之一，与 Datadog 等并列。",
        colorKey: "dynatrace",
        billingURL: URL(string: "https://myaccount.dynatrace.com")!,
        credentialSetupURL: URL(string: "https://docs.dynatrace.com/docs/dynatrace-api/account-management-api/dynatrace-platform-subscription-api/cost/get-cost")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["dynatrace", "dps", "platform subscription", "account-uac-read", "currencyCode"]
    )

    public static let zoom = ProviderDescriptor(
        id: .zoom,
        displayName: "Zoom",
        kind: .usage,
        category: .collaboration,
        tier: .one,
        tierReason: "视频会议企业支出的寡头核心。",
        colorKey: "zoom",
        billingURL: URL(string: "https://zoom.us/billing")!,
        credentialSetupURL: URL(string: "https://developers.zoom.us/docs/api/billing/ma/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["zoom", "billing invoices", "total_amount", "pro"]
    )

    public static let namecom = ProviderDescriptor(
        id: .namecom,
        displayName: "Name.com",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "域名注册中小型选手，份额小于 GoDaddy/Namecheap。",
        colorKey: "namecom",
        billingURL: URL(string: "https://www.name.com")!,
        credentialSetupURL: URL(string: "https://docs.name.com/api/v1/reference/orders/get-order")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["name.com", "namecom", "finalAmount", "orders"]
    )

    public static let ovhcloud = ProviderDescriptor(
        id: .ovhcloud,
        displayName: "OVHcloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "欧洲公有云/裸金属的强挑战者，主权云叙事清晰。",
        colorKey: "ovhcloud",
        billingURL: URL(string: "https://www.ovhcloud.com")!,
        credentialSetupURL: URL(string: "https://api.ovh.com/console/#/me/bill~GET")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["ovh", "ovhcloud", "priceWithTax", "me/bill"]
    )

    public static let sakuracloud = ProviderDescriptor(
        id: .sakuracloud,
        displayName: "Sakura Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "日本本地云的强挑战者，中小企业渗透高。",
        colorKey: "sakuracloud",
        billingURL: URL(string: "https://secure.sakura.ad.jp")!,
        credentialSetupURL: URL(string: "https://manual.sakura.ad.jp/cloud/api/billapi.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["sakura", "さくら", "bill/by-contract", "JPY"]
    )

    public static let akamai = ProviderDescriptor(
        id: .akamai,
        displayName: "Akamai",
        kind: .usage,
        category: .networkEdge,
        tier: .one,
        tierReason: "企业 CDN/边缘安全的寡头之一，份额长期稳固。",
        colorKey: "akamai",
        billingURL: URL(string: "https://control.akamai.com")!,
        credentialSetupURL: URL(string: "https://techdocs.akamai.com/invoicing")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["akamai", "invoicing-api", "invoiceTotal", "EdgeGrid"]
    )
}
