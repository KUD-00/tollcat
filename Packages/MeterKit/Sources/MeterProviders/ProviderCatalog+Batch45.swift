import Foundation
import MeterCore

extension ProviderCatalog {
    public static let amberelectric = ProviderDescriptor(
        id: .amberelectric,
        displayName: "Amber Electric",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "澳洲零售电力与智能电价细分里的中小型选手。",
        colorKey: "amberelectric",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额接口缺币种字段，无法作为账单 SoT。",
        searchKeywords: ["amber electric", "electricity", "australia", "电力"]
    )

    public static let shiphero = ProviderDescriptor(
        id: .shiphero,
        displayName: "ShipHero",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "DTC 履约/WMS 细分挑战者，规模小于大型 3PL。",
        colorKey: "shiphero",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "金额字段缺币种，无法作为账单 SoT。",
        searchKeywords: ["shiphero", "wms", "fulfillment", "履约"]
    )

    public static let worldstream = ProviderDescriptor(
        id: .worldstream,
        displayName: "Worldstream",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "荷兰机柜/裸金属区域性主机商。",
        colorKey: "worldstream",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "用量/账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["worldstream", "dedicated", "netherlands", "裸金属"]
    )

    public static let imprezahost = ProviderDescriptor(
        id: .imprezahost,
        displayName: "Impreza Host",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "小众主机商，区域与品牌认知有限。",
        colorKey: "imprezahost",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["impreza", "hosting", "vps"]
    )

    public static let bitwarden = ProviderDescriptor(
        id: .bitwarden,
        displayName: "Bitwarden",
        kind: .subscription,
        category: .authSecurity,
        tier: .two,
        tierReason: "开源密码管理强挑战者，企业采购常见短名单。",
        colorKey: "bitwarden",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "billing 接口金额缺币种或非买家账单形态，无法作为账单 SoT。",
        searchKeywords: ["bitwarden", "password", "密码管理"]
    )

    public static let sematext = ProviderDescriptor(
        id: .sematext,
        displayName: "Sematext",
        kind: .usage,
        category: .observability,
        tier: .three,
        tierReason: "日志/APM 可观测性中小厂商。",
        colorKey: "sematext",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["sematext", "logs", "apm", "日志"]
    )

    public static let crusoe = ProviderDescriptor(
        id: .crusoe,
        displayName: "Crusoe",
        kind: .usage,
        category: .gpuCompute,
        tier: .two,
        tierReason: "低碳能源驱动的 GPU 云挑战者。",
        colorKey: "crusoe",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "costs 接口缺币种或非期间账单合计，无法作为账单 SoT。",
        searchKeywords: ["crusoe", "gpu", "cloud", "energy"]
    )

    public static let here = ProviderDescriptor(
        id: .here,
        displayName: "HERE",
        kind: .usage,
        category: .networkEdge,
        tier: .two,
        tierReason: "地图与定位平台强挑战者（汽车/物流场景）。",
        colorKey: "here",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "usage 计量无账单金额币种，无法作为账单 SoT。",
        searchKeywords: ["here", "here maps", "maps", "地图", "定位"]
    )

    public static let bluerocktel = ProviderDescriptor(
        id: .bluerocktel,
        displayName: "BlueRockTel",
        kind: .usage,
        category: .messaging,
        tier: .four,
        tierReason: "小众电信/语音 API 供应商。",
        colorKey: "bluerocktel",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["bluerocktel", "telecom", "voice"]
    )

    public static let ucloud = ProviderDescriptor(
        id: .ucloud,
        displayName: "UCloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "中国公有云第二梯队常见选项。",
        colorKey: "ucloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "ListUBillDetail 金额缺可用币种/形态，无法作为账单 SoT。",
        searchKeywords: ["ucloud", "优刻得", "云主机"]
    )

    public static let qingcloud = ProviderDescriptor(
        id: .qingcloud,
        displayName: "QingCloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "青云公有云/混合云区域性选手。",
        colorKey: "qingcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "GetChargeSums 金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["qingcloud", "青云", "云"]
    )

    public static let ctyun = ProviderDescriptor(
        id: .ctyun,
        displayName: "CTYun",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "中国电信天翼云，国内政企常见短名单。",
        colorKey: "ctyun",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单明细缺稳定币种字段，无法作为账单 SoT。",
        searchKeywords: ["ctyun", "天翼云", "中国电信"]
    )

    public static let ecloud = ProviderDescriptor(
        id: .ecloud,
        displayName: "China Mobile eCloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "中国移动云，政企采购常见选项。",
        colorKey: "ecloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单接口缺币种或非标准金额合计，无法作为账单 SoT。",
        searchKeywords: ["ecloud", "移动云", "china mobile", "中国移动"]
    )

    public static let zenlayer = ProviderDescriptor(
        id: .zenlayer,
        displayName: "Zenlayer",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "边缘云/跨国互联中型选手。",
        colorKey: "zenlayer",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["zenlayer", "edge", "cdn", "边缘"]
    )

    public static let selectel = ProviderDescriptor(
        id: .selectel,
        displayName: "Selectel",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "俄语区云与机柜区域龙头之一。",
        colorKey: "selectel",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "stats/账单金额缺币种，无法作为账单 SoT。",
        searchKeywords: ["selectel", "russia", "vps", "cloud"]
    )

    public static let storyblok = ProviderDescriptor(
        id: .storyblok,
        displayName: "Storyblok",
        kind: .subscription,
        category: .cms,
        tier: .two,
        tierReason: "头less CMS 强挑战者。",
        colorKey: "storyblok",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "invoices 币种未文档化/不稳定，无法作为账单 SoT。",
        searchKeywords: ["storyblok", "cms", "headless"]
    )

    public static let elasticemail = ProviderDescriptor(
        id: .elasticemail,
        displayName: "Elastic Email",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "交易/营销邮件中小厂商。",
        colorKey: "elasticemail",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "LoadPaymentHistory 缺币种，无法作为账单 SoT。",
        searchKeywords: ["elastic email", "email", "smtp", "邮件"]
    )

    public static let baiducloud = ProviderDescriptor(
        id: .baiducloud,
        displayName: "Baidu AI Cloud",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "百度智能云，国内 AI/云采购短名单。",
        colorKey: "baiducloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "finance 账单接口缺稳定币种/金额形态，无法作为账单 SoT。",
        searchKeywords: ["baidu", "百度云", "智能云", "ai"]
    )

    public static let jdcloud = ProviderDescriptor(
        id: .jdcloud,
        displayName: "JD Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "京东云，国内电商/政企场景常见选项。",
        colorKey: "jdcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "bill summary 缺币种，无法作为账单 SoT。",
        searchKeywords: ["jd cloud", "京东云"]
    )

    public static let apivideo = ProviderDescriptor(
        id: .apivideo,
        displayName: "api.video",
        kind: .usage,
        category: .media,
        tier: .three,
        tierReason: "视频 API 中小厂商。",
        colorKey: "apivideo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅分钟等用量单位，无账单金额币种，无法作为账单 SoT。",
        searchKeywords: ["api.video", "video", "视频"]
    )

    public static let bitmovin = ProviderDescriptor(
        id: .bitmovin,
        displayName: "Bitmovin",
        kind: .usage,
        category: .media,
        tier: .three,
        tierReason: "视频编码/播放企业向中型选手。",
        colorKey: "bitmovin",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅 GB 等用量，无账单金额币种，无法作为账单 SoT。",
        searchKeywords: ["bitmovin", "encoding", "video", "编码"]
    )

    public static let airtable = ProviderDescriptor(
        id: .airtable,
        displayName: "Airtable",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "低代码表格/业务库市场默认短名单。",
        colorKey: "airtable",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票/金额 API。",
        searchKeywords: ["airtable", "spreadsheet", "表格"]
    )

    public static let clickup = ProviderDescriptor(
        id: .clickup,
        displayName: "ClickUp",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "全能项目管理强挑战者。",
        colorKey: "clickup",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["clickup", "project", "项目管理"]
    )

    public static let asana = ProviderDescriptor(
        id: .asana,
        displayName: "Asana",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "项目管理企业采购默认选项之一。",
        colorKey: "asana",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["asana", "work management", "项目管理"]
    )

    public static let zendesk = ProviderDescriptor(
        id: .zendesk,
        displayName: "Zendesk",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "客服/工单市场近乎默认选项。",
        colorKey: "zendesk",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/伙伴门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["zendesk", "support", "客服", "工单"]
    )

    public static let customerio = ProviderDescriptor(
        id: .customerio,
        displayName: "Customer.io",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "产品导向消息自动化强挑战者。",
        colorKey: "customerio",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["customer.io", "customerio", "messaging", "营销自动化"]
    )

    public static let activecampaign = ProviderDescriptor(
        id: .activecampaign,
        displayName: "ActiveCampaign",
        kind: .subscription,
        category: .messaging,
        tier: .two,
        tierReason: "营销自动化强挑战者。",
        colorKey: "activecampaign",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["activecampaign", "marketing", "营销自动化"]
    )

    public static let canva = ProviderDescriptor(
        id: .canva,
        displayName: "Canva",
        kind: .subscription,
        category: .media,
        tier: .one,
        tierReason: "设计 SaaS 大众市场绝对龙头。",
        colorKey: "canva",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台订阅账单，没有公开买家发票 API。",
        searchKeywords: ["canva", "design", "设计"]
    )

    public static let hostinger = ProviderDescriptor(
        id: .hostinger,
        displayName: "Hostinger",
        kind: .subscription,
        category: .hosting,
        tier: .two,
        tierReason: "大众主机/VPS 高销量挑战者。",
        colorKey: "hostinger",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["hostinger", "hosting", "vps", "主机"]
    )

    public static let kakaocloud = ProviderDescriptor(
        id: .kakaocloud,
        displayName: "Kakao Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "韩国公有云区域性选项。",
        colorKey: "kakaocloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["kakao cloud", "카카오", "韩国云"]
    )

    public static let mercari = ProviderDescriptor(
        id: .mercari,
        displayName: "Mercari",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "日本二手电商平台；开发者计费非核心账单场景。",
        colorKey: "mercari",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "没有公开买家账单/发票 API。",
        searchKeywords: ["mercari", "メルカリ", "marketplace"]
    )

    public static let linedevelopers = ProviderDescriptor(
        id: .linedevelopers,
        displayName: "LINE Developers",
        kind: .usage,
        category: .messaging,
        tier: .one,
        tierReason: "日本/东南亚即时通讯平台消息 API 龙头。",
        colorKey: "linedevelopers",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "billing 仅控制台，没有公开买家发票金额 API。",
        searchKeywords: ["line", "line developers", "messaging", "ライン"]
    )

    public static let cybozu = ProviderDescriptor(
        id: .cybozu,
        displayName: "Cybozu / kintone",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "日本业务应用/kintone 低代码区域龙头。",
        colorKey: "cybozu",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["cybozu", "kintone", "キントーン", "低コード"]
    )

    public static let onepassword = ProviderDescriptor(
        id: .onepassword,
        displayName: "1Password",
        kind: .subscription,
        category: .authSecurity,
        tier: .one,
        tierReason: "团队密码管理企业采购默认短名单。",
        colorKey: "onepassword",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Business 账单仅控制台，没有公开买家发票 API。",
        searchKeywords: ["1password", "onepassword", "password", "密码"]
    )

    public static let lastpass = ProviderDescriptor(
        id: .lastpass,
        displayName: "LastPass",
        kind: .subscription,
        category: .authSecurity,
        tier: .two,
        tierReason: "密码管理老牌挑战者。",
        colorKey: "lastpass",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["lastpass", "password", "密码"]
    )

    public static let duo = ProviderDescriptor(
        id: .duo,
        displayName: "Duo",
        kind: .subscription,
        category: .authSecurity,
        tier: .one,
        tierReason: "Cisco 旗下 MFA，企业采购常见默认项。",
        colorKey: "duo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/伙伴门户账单，没有公开买家发票 API。",
        searchKeywords: ["duo", "duo security", "mfa", "cisco"]
    )

    public static let aftership = ProviderDescriptor(
        id: .aftership,
        displayName: "AfterShip",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "物流追踪 SaaS 强挑战者。",
        colorKey: "aftership",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["aftership", "tracking", "物流追踪"]
    )

    public static let dhl = ProviderDescriptor(
        id: .dhl,
        displayName: "DHL",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "国际快递默认短名单。",
        colorKey: "dhl",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "买家账单走门户/EDI，没有可用的公开发票金额 API。",
        searchKeywords: ["dhl", "express", "shipping", "快递"]
    )

    public static let fedex = ProviderDescriptor(
        id: .fedex,
        displayName: "FedEx",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "国际快递默认短名单。",
        colorKey: "fedex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Billing 走门户，没有公开买家发票金额 HTTP API。",
        searchKeywords: ["fedex", "shipping", "快递"]
    )

    public static let ups = ProviderDescriptor(
        id: .ups,
        displayName: "UPS",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "国际快递默认短名单。",
        colorKey: "ups",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "UPS Billing 仅门户，没有公开买家发票金额 API。",
        searchKeywords: ["ups", "ups billing", "shipping", "快递"]
    )

    public static let royalmail = ProviderDescriptor(
        id: .royalmail,
        displayName: "Royal Mail",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "英国邮政寄递默认选项。",
        colorKey: "royalmail",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["royal mail", "uk post", "shipping"]
    )

    public static let parcel2go = ProviderDescriptor(
        id: .parcel2go,
        displayName: "Parcel2Go",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "英国包裹比价寄递聚合中小厂商。",
        colorKey: "parcel2go",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户/账户账单，没有公开买家发票 API。",
        searchKeywords: ["parcel2go", "parcel", "uk shipping"]
    )

    public static let dpd = ProviderDescriptor(
        id: .dpd,
        displayName: "DPD",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "欧洲包裹寄递强品牌。",
        colorKey: "dpd",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["dpd", "shipping", "parcel", "快递"]
    )

    public static let gls = ProviderDescriptor(
        id: .gls,
        displayName: "GLS",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "欧洲陆运包裹强品牌。",
        colorKey: "gls",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["gls", "shipping", "parcel"]
    )

    public static let appdynamics = ProviderDescriptor(
        id: .appdynamics,
        displayName: "AppDynamics",
        kind: .subscription,
        category: .observability,
        tier: .one,
        tierReason: "Cisco 旗下 APM 企业默认短名单。",
        colorKey: "appdynamics",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/Cisco 商务门户，没有公开买家发票 API。",
        searchKeywords: ["appdynamics", "apm", "cisco"]
    )

    public static let infomaniak = ProviderDescriptor(
        id: .infomaniak,
        displayName: "Infomaniak",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "瑞士主机/云区域性选手。",
        colorKey: "infomaniak",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 schema 不足以构成买家期间账单金额 API。",
        searchKeywords: ["infomaniak", "swiss", "hosting", "cloud"]
    )

    public static let webdock = ProviderDescriptor(
        id: .webdock,
        displayName: "Webdock",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "丹麦 VPS 小众主机商。",
        colorKey: "webdock",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["webdock", "vps", "denmark"]
    )

    public static let cubbit = ProviderDescriptor(
        id: .cubbit,
        displayName: "Cubbit",
        kind: .usage,
        category: .storage,
        tier: .four,
        tierReason: "分布式对象存储早期选手。",
        colorKey: "cubbit",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["cubbit", "storage", "s3", "对象存储"]
    )

    public static let beehiiv = ProviderDescriptor(
        id: .beehiiv,
        displayName: "Beehiiv",
        kind: .subscription,
        category: .messaging,
        tier: .two,
        tierReason: "创作者 Newsletter 强挑战者。",
        colorKey: "beehiiv",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["beehiiv", "newsletter", "email", "邮件"]
    )

    public static let packiyo = ProviderDescriptor(
        id: .packiyo,
        displayName: "Packiyo",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "履约/仓储小众 SaaS。",
        colorKey: "packiyo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["packiyo", "fulfillment", "wms"]
    )

    public static let greenely = ProviderDescriptor(
        id: .greenely,
        displayName: "Greenely",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "北欧家庭能源管理细分选手。",
        colorKey: "greenely",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/App 账单，没有公开买家发票 API。",
        searchKeywords: ["greenely", "energy", "sweden", "电力"]
    )

    public static let gorgias = ProviderDescriptor(
        id: .gorgias,
        displayName: "Gorgias",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "电商客服台强挑战者。",
        colorKey: "gorgias",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["gorgias", "helpdesk", "shopify", "客服"]
    )

    public static let jwplayer = ProviderDescriptor(
        id: .jwplayer,
        displayName: "JW Player",
        kind: .usage,
        category: .media,
        tier: .two,
        tierReason: "企业视频播放/托管老牌挑战者。",
        colorKey: "jwplayer",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["jw player", "jwplayer", "video", "视频"]
    )

    public static let cachefly = ProviderDescriptor(
        id: .cachefly,
        displayName: "CacheFly",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "CDN 中型选手。",
        colorKey: "cachefly",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["cachefly", "cdn"]
    )

    public static let cherryservers = ProviderDescriptor(
        id: .cherryservers,
        displayName: "Cherry Servers",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "欧洲裸金属/云主机中小厂商。",
        colorKey: "cherryservers",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["cherry servers", "bare metal", "裸金属"]
    )

    public static let sav = ProviderDescriptor(
        id: .sav,
        displayName: "Sav.com",
        kind: .subscription,
        category: .networkEdge,
        tier: .four,
        tierReason: "域名注册小众商。",
        colorKey: "sav",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台余额/账单，没有公开买家发票 API。",
        searchKeywords: ["sav.com", "sav", "domains", "域名"]
    )

    public static let hover = ProviderDescriptor(
        id: .hover,
        displayName: "Hover",
        kind: .subscription,
        category: .networkEdge,
        tier: .three,
        tierReason: "域名注册友好型中小品牌。",
        colorKey: "hover",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["hover", "domains", "域名"]
    )

    public static let epik = ProviderDescriptor(
        id: .epik,
        displayName: "Epik",
        kind: .subscription,
        category: .networkEdge,
        tier: .four,
        tierReason: "域名注册小众商。",
        colorKey: "epik",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["epik", "domains", "域名"]
    )

    public static let eurodns = ProviderDescriptor(
        id: .eurodns,
        displayName: "EuroDNS",
        kind: .subscription,
        category: .networkEdge,
        tier: .three,
        tierReason: "欧洲域名/DNS 区域性厂商。",
        colorKey: "eurodns",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["eurodns", "domains", "dns", "域名"]
    )

    public static let mezmo = ProviderDescriptor(
        id: .mezmo,
        displayName: "Mezmo",
        kind: .usage,
        category: .observability,
        tier: .three,
        tierReason: "日志管道（原 LogDNA）中型选手。",
        colorKey: "mezmo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["mezmo", "logdna", "logs", "日志"]
    )

    public static let chronosphere = ProviderDescriptor(
        id: .chronosphere,
        displayName: "Chronosphere",
        kind: .usage,
        category: .observability,
        tier: .two,
        tierReason: "大规模可观测性（Prometheus/持久化）强挑战者。",
        colorKey: "chronosphere",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["chronosphere", "prometheus", "observability", "可观测"]
    )

    public static let highlight = ProviderDescriptor(
        id: .highlight,
        displayName: "Highlight.io",
        kind: .usage,
        category: .observability,
        tier: .three,
        tierReason: "会话回放+观测一体化早期挑战者。",
        colorKey: "highlight",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["highlight.io", "highlight", "session replay"]
    )

    public static let ultahost = ProviderDescriptor(
        id: .ultahost,
        displayName: "Ultahost",
        kind: .subscription,
        category: .hosting,
        tier: .four,
        tierReason: "大众主机小众品牌。",
        colorKey: "ultahost",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["ultahost", "hosting", "vps"]
    )

    public static let hostpresto = ProviderDescriptor(
        id: .hostpresto,
        displayName: "HostPresto",
        kind: .subscription,
        category: .hosting,
        tier: .four,
        tierReason: "英国主机小众商。",
        colorKey: "hostpresto",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["hostpresto", "hosting", "uk"]
    )

    public static let whiplash = ProviderDescriptor(
        id: .whiplash,
        displayName: "Whiplash",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "履约物流（Radial 体系）中型选手。",
        colorKey: "whiplash",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/门户账单，没有公开买家发票 API。",
        searchKeywords: ["whiplash", "fulfillment", "radial", "履约"]
    )

    public static let customcat = ProviderDescriptor(
        id: .customcat,
        displayName: "CustomCat",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "印花 POD 履约中型选手。",
        colorKey: "customcat",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/门户账单，没有公开买家发票 API。",
        searchKeywords: ["customcat", "pod", "print on demand", "印花"]
    )

    public static let printedmint = ProviderDescriptor(
        id: .printedmint,
        displayName: "PrintedMint",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "POD 履约小众品牌。",
        colorKey: "printedmint",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["printedmint", "pod", "print on demand"]
    )

    public static let shineon = ProviderDescriptor(
        id: .shineon,
        displayName: "ShineOn",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "饰品 POD 履约小众品牌。",
        colorKey: "shineon",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["shineon", "pod", "jewelry"]
    )

    public static let eneco = ProviderDescriptor(
        id: .eneco,
        displayName: "Eneco",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "荷兰能源零售区域龙头之一。",
        colorKey: "eneco",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户/App 账单，没有公开买家发票金额 API。",
        searchKeywords: ["eneco", "energy", "netherlands", "电力", "天然气"]
    )

    public static let locaweb = ProviderDescriptor(
        id: .locaweb,
        displayName: "Locaweb",
        kind: .subscription,
        category: .hosting,
        tier: .two,
        tierReason: "巴西主机/云区域龙头之一。",
        colorKey: "locaweb",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["locaweb", "brazil", "hosting"]
    )

    public static let termina = ProviderDescriptor(
        id: .termina,
        displayName: "Termina",
        kind: .usage,
        category: .gpuCompute,
        tier: .four,
        tierReason: "GPU/算力小众供应商。",
        colorKey: "termina",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["termina", "gpu", "compute"]
    )

    public static let withflex = ProviderDescriptor(
        id: .withflex,
        displayName: "Flex (withflex)",
        kind: .subscription,
        category: .payments,
        tier: .four,
        tierReason: "PSP/嵌入式支付小众方案。",
        colorKey: "withflex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "属 PSP 类/卖家侧形态，没有可用的买家期间账单 API。",
        searchKeywords: ["withflex", "flex", "psp", "payments"]
    )

    public static let requestfinance = ProviderDescriptor(
        id: .requestfinance,
        displayName: "Request Finance",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "加密/法币应付账款工具中小厂商。",
        colorKey: "requestfinance",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "产品形态是应付/开票工具，不是买家云账单 SoT。",
        searchKeywords: ["request.finance", "request finance", "crypto", "ap"]
    )

    public static let extensiv = ProviderDescriptor(
        id: .extensiv,
        displayName: "Extensiv",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "多渠道履约/仓储中型选手。",
        colorKey: "extensiv",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开 API 账单为空/不可用，仅门户。",
        searchKeywords: ["extensiv", "fulfillment", "wms"]
    )

    public static let packlink = ProviderDescriptor(
        id: .packlink,
        displayName: "Packlink",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "欧洲寄递聚合平台。",
        colorKey: "packlink",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["packlink", "shipping", "parcel"]
    )

    public static let shippingbo = ProviderDescriptor(
        id: .shippingbo,
        displayName: "Shippingbo",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "法语区电商物流 OMS 小众商。",
        colorKey: "shippingbo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["shippingbo", "oms", "shipping", "france"]
    )

    public static let boxtal = ProviderDescriptor(
        id: .boxtal,
        displayName: "Boxtal",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "法国寄递比价/聚合中型选手。",
        colorKey: "boxtal",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["boxtal", "shipping", "france"]
    )

    public static let myparcel = ProviderDescriptor(
        id: .myparcel,
        displayName: "MyParcel",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "荷比卢寄递 API 区域选手。",
        colorKey: "myparcel",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单以 PDF/门户为主，没有可用的公开金额 JSON API。",
        searchKeywords: ["myparcel", "shipping", "netherlands"]
    )

    public static let webshipper = ProviderDescriptor(
        id: .webshipper,
        displayName: "Webshipper",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "北欧电商物流小众商。",
        colorKey: "webshipper",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["webshipper", "shipping", "denmark"]
    )

    public static let coolrunner = ProviderDescriptor(
        id: .coolrunner,
        displayName: "Coolrunner",
        kind: .usage,
        category: .other,
        tier: .four,
        tierReason: "丹麦寄递聚合小众商。",
        colorKey: "coolrunner",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["coolrunner", "shipping", "denmark"]
    )

    public static let billbee = ProviderDescriptor(
        id: .billbee,
        displayName: "Billbee",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "德语区电商 ERP/开票卖家工具。",
        colorKey: "billbee",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家开票/ERP 形态，不是买家云账单 SoT。",
        searchKeywords: ["billbee", "erp", "invoicing", "卖家"]
    )

    public static let beam = ProviderDescriptor(
        id: .beam,
        displayName: "Beam",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "无服务器 GPU 推理中型挑战者。",
        colorKey: "beam",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票金额 API。",
        searchKeywords: ["beam.cloud", "beam", "gpu", "serverless"]
    )

    public static let inferless = ProviderDescriptor(
        id: .inferless,
        displayName: "Inferless",
        kind: .usage,
        category: .aiInference,
        tier: .four,
        tierReason: "模型部署小众平台。",
        colorKey: "inferless",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["inferless", "inference", "gpu"]
    )

    public static let fluidstack = ProviderDescriptor(
        id: .fluidstack,
        displayName: "Fluidstack",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "分布式 GPU 云中型选手。",
        colorKey: "fluidstack",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["fluidstack", "gpu", "cloud"]
    )

    public static let shadeform = ProviderDescriptor(
        id: .shadeform,
        displayName: "Shadeform",
        kind: .usage,
        category: .gpuCompute,
        tier: .four,
        tierReason: "GPU 云聚合小众平台。",
        colorKey: "shadeform",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["shadeform", "gpu"]
    )

    public static let thundercompute = ProviderDescriptor(
        id: .thundercompute,
        displayName: "Thunder Compute",
        kind: .usage,
        category: .gpuCompute,
        tier: .four,
        tierReason: "低价 GPU 云早期选手。",
        colorKey: "thundercompute",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["thunder compute", "thundercompute", "gpu"]
    )

    public static let tensordock = ProviderDescriptor(
        id: .tensordock,
        displayName: "TensorDock",
        kind: .prepaid,
        category: .gpuCompute,
        tier: .three,
        tierReason: "社区 GPU 云中型选手。",
        colorKey: "tensordock",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预付费余额模型，不是期间买家发票 SoT。",
        searchKeywords: ["tensordock", "gpu", "prepaid", "预付费"]
    )

    public static let anyscale = ProviderDescriptor(
        id: .anyscale,
        displayName: "Anyscale",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "Ray 商业化平台，企业 AI 基础设施短名单。",
        colorKey: "anyscale",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票金额 API。",
        searchKeywords: ["anyscale", "ray", "ai"]
    )

    public static let ai21 = ProviderDescriptor(
        id: .ai21,
        displayName: "AI21",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "大模型实验室强挑战者。",
        colorKey: "ai21",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["ai21", "jurassic", "llm"]
    )

    public static let sambanova = ProviderDescriptor(
        id: .sambanova,
        displayName: "SambaNova",
        kind: .usage,
        category: .aiInference,
        tier: .two,
        tierReason: "企业 AI 芯片/云推断短名单挑战者。",
        colorKey: "sambanova",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/销售门户账单，没有公开买家发票 API。",
        searchKeywords: ["sambanova", "ai", "inference"]
    )

    public static let wandb = ProviderDescriptor(
        id: .wandb,
        displayName: "Weights & Biases",
        kind: .subscription,
        category: .devTools,
        tier: .one,
        tierReason: "MLOps 实验追踪近乎默认选项。",
        colorKey: "wandb",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["wandb", "weights and biases", "mlops"]
    )

    public static let clarifai = ProviderDescriptor(
        id: .clarifai,
        displayName: "Clarifai",
        kind: .usage,
        category: .aiInference,
        tier: .three,
        tierReason: "计算机视觉 API 老牌中型选手。",
        colorKey: "clarifai",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["clarifai", "vision", "ai", "视觉"]
    )

    public static let easydns = ProviderDescriptor(
        id: .easydns,
        displayName: "EasyDNS",
        kind: .subscription,
        category: .networkEdge,
        tier: .three,
        tierReason: "域名/DNS 老牌中小厂商。",
        colorKey: "easydns",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["easydns", "dns", "domains", "域名"]
    )

    public static let binero = ProviderDescriptor(
        id: .binero,
        displayName: "Binero",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "瑞典云/主机小众商。",
        colorKey: "binero",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["binero", "sweden", "cloud", "hosting"]
    )

    public static let dogado = ProviderDescriptor(
        id: .dogado,
        displayName: "dogado",
        kind: .subscription,
        category: .hosting,
        tier: .three,
        tierReason: "德语区主机区域性厂商。",
        colorKey: "dogado",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["dogado", "hosting", "germany"]
    )

    public static let monday = ProviderDescriptor(
        id: .monday,
        displayName: "Monday.com",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "工作 OS/项目管理大众市场龙头之一。",
        colorKey: "monday",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["monday.com", "monday", "workos", "项目管理"]
    )

    public static let teachable = ProviderDescriptor(
        id: .teachable,
        displayName: "Teachable",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "创作者课程平台强挑战者。",
        colorKey: "teachable",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["teachable", "courses", "课程"]
    )

    public static let thinkific = ProviderDescriptor(
        id: .thinkific,
        displayName: "Thinkific",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "创作者课程平台强挑战者。",
        colorKey: "thinkific",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["thinkific", "courses", "课程"]
    )

    public static let hex = ProviderDescriptor(
        id: .hex,
        displayName: "Hex",
        kind: .subscription,
        category: .analytics,
        tier: .two,
        tierReason: "协作式数据分析笔记本强挑战者。",
        colorKey: "hex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["hex", "hex.tech", "analytics", "notebook"]
    )

    public static let mode = ProviderDescriptor(
        id: .mode,
        displayName: "Mode",
        kind: .subscription,
        category: .analytics,
        tier: .two,
        tierReason: "分析/SQL 协作老牌挑战者（Salesforce 体系）。",
        colorKey: "mode",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["mode analytics", "mode", "sql"]
    )

    public static let sigma = ProviderDescriptor(
        id: .sigma,
        displayName: "Sigma",
        kind: .subscription,
        category: .analytics,
        tier: .two,
        tierReason: "云数据仓库上的电子表格分析强挑战者。",
        colorKey: "sigma",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["sigma computing", "sigma", "analytics"]
    )

    public static let looker = ProviderDescriptor(
        id: .looker,
        displayName: "Looker",
        kind: .subscription,
        category: .analytics,
        tier: .one,
        tierReason: "BI 企业采购默认短名单（Google Cloud）。",
        colorKey: "looker",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/GCP 商务，没有独立买家发票金额 API。",
        searchKeywords: ["looker", "bi", "google", "分析"]
    )

    public static let statuspage = ProviderDescriptor(
        id: .statuspage,
        displayName: "Statuspage",
        kind: .subscription,
        category: .observability,
        tier: .two,
        tierReason: "状态页市场默认选项（Atlassian）。",
        colorKey: "statuspage",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/Atlassian 商务门户，没有公开买家发票 API。",
        searchKeywords: ["statuspage", "status page", "atlassian"]
    )

    public static let incidentio = ProviderDescriptor(
        id: .incidentio,
        displayName: "incident.io",
        kind: .subscription,
        category: .observability,
        tier: .two,
        tierReason: "事件响应协作强挑战者。",
        colorKey: "incidentio",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["incident.io", "incident", "oncall", "事故"]
    )

    public static let rootly = ProviderDescriptor(
        id: .rootly,
        displayName: "Rootly",
        kind: .subscription,
        category: .observability,
        tier: .three,
        tierReason: "事件管理中型挑战者。",
        colorKey: "rootly",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["rootly", "incident", "oncall"]
    )

    public static let cloudhealth = ProviderDescriptor(
        id: .cloudhealth,
        displayName: "CloudHealth",
        kind: .subscription,
        category: .observability,
        tier: .one,
        tierReason: "云成本管理企业默认短名单（VMware/Broadcom）。",
        colorKey: "cloudhealth",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "伙伴/企业门户形态，没有公开买家发票金额 API。",
        searchKeywords: ["cloudhealth", "vmware", "finops", "云成本"]
    )

    public static let apptio = ProviderDescriptor(
        id: .apptio,
        displayName: "Apptio",
        kind: .subscription,
        category: .analytics,
        tier: .one,
        tierReason: "IT 财务/FinOps 企业默认短名单（IBM）。",
        colorKey: "apptio",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "企业商务/伙伴门户，没有公开买家发票 API。",
        searchKeywords: ["apptio", "ibm", "finops", "tbm"]
    )

    public static let kubecost = ProviderDescriptor(
        id: .kubecost,
        displayName: "Kubecost",
        kind: .subscription,
        category: .observability,
        tier: .two,
        tierReason: "Kubernetes 成本可见性强挑战者。",
        colorKey: "kubecost",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/许可账单，没有公开买家发票金额 API。",
        searchKeywords: ["kubecost", "kubernetes", "finops", "k8s"]
    )

    public static let softbankcloud = ProviderDescriptor(
        id: .softbankcloud,
        displayName: "SoftBank Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "日本软银云区域性选项。",
        colorKey: "softbankcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/企业合同账单，没有公开买家发票 API。",
        searchKeywords: ["softbank", "ソフトバンク", "cloud", "日本云"]
    )

    public static let yahoojpcloud = ProviderDescriptor(
        id: .yahoojpcloud,
        displayName: "Yahoo! JAPAN Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "雅虎日本云区域性选项。",
        colorKey: "yahoojpcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["yahoo japan", "yahoo jp cloud", "ヤフー"]
    )

    public static let nttdocomo = ProviderDescriptor(
        id: .nttdocomo,
        displayName: "NTT Docomo Bills",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "日本通信运营商账单场景龙头。",
        colorKey: "nttdocomo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "运营商账单仅门户/OAuth 缺可用凭据字段，无法作为产品账单 SoT。",
        searchKeywords: ["ntt", "docomo", "ドコモ", "通信费"]
    )

    public static let otc = ProviderDescriptor(
        id: .otc,
        displayName: "Open Telekom Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "Deutsche Telekom 公有云区域性选项。",
        colorKey: "otc",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台/企业合同账单，没有公开买家发票金额 API。",
        searchKeywords: ["otc", "open telekom cloud", "deutsche telekom", "t-systems"]
    )

    public static let statsig = ProviderDescriptor(
        id: .statsig,
        displayName: "Statsig",
        kind: .usage,
        category: .analytics,
        tier: .two,
        tierReason: "功能开关/实验平台强挑战者。",
        colorKey: "statsig",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单导出以 CSV/控制台为主，没有可用的公开发票金额 API。",
        searchKeywords: ["statsig", "feature flags", "experiment", "实验"]
    )

    public static let noonahq = ProviderDescriptor(
        id: .noonahq,
        displayName: "Noona HQ",
        kind: .subscription,
        category: .other,
        tier: .four,
        tierReason: "预约/门店运营小众 SaaS。",
        colorKey: "noonahq",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅控制台账单，没有公开买家发票 API。",
        searchKeywords: ["noona", "noona hq", "booking", "预约"]
    )

    public static let googleads = ProviderDescriptor(
        id: .googleads,
        displayName: "Google Ads",
        kind: .usage,
        category: .analytics,
        tier: .one,
        tierReason: "数字广告支出绝对龙头。",
        colorKey: "googleads",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "InvoiceService 需 OAuth，缺产品可用的只读凭据字段模型（HOLD）。",
        searchKeywords: ["google ads", "adwords", "广告"]
    )

    public static let metabusiness = ProviderDescriptor(
        id: .metabusiness,
        displayName: "Meta Business Invoices",
        kind: .usage,
        category: .analytics,
        tier: .one,
        tierReason: "社交广告支出绝对龙头之一。",
        colorKey: "metabusiness",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "business_invoices 需 Business/OAuth，缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["meta", "facebook ads", "business invoices", "广告"]
    )

    public static let microsoftads = ProviderDescriptor(
        id: .microsoftads,
        displayName: "Microsoft Advertising",
        kind: .usage,
        category: .analytics,
        tier: .one,
        tierReason: "搜索广告第二极。",
        colorKey: "microsoftads",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "GetBillingDocuments 需 OAuth，缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["microsoft advertising", "bing ads", "广告"]
    )

    public static let nebius = ProviderDescriptor(
        id: .nebius,
        displayName: "Nebius",
        kind: .usage,
        category: .gpuCompute,
        tier: .two,
        tierReason: "GPU 云新兴挑战者。",
        colorKey: "nebius",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "FOCUS 导出过重/非即时账单 API，产品模型未覆盖（HOLD）。",
        searchKeywords: ["nebius", "gpu", "focus", "cloud"]
    )

    public static let temporal = ProviderDescriptor(
        id: .temporal,
        displayName: "Temporal Cloud",
        kind: .usage,
        category: .devTools,
        tier: .two,
        tierReason: "工作流引擎托管强挑战者。",
        colorKey: "temporal",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "FOCUS 导出过重，产品模型未覆盖（HOLD）。",
        searchKeywords: ["temporal", "workflow", "focus"]
    )

    public static let yandexcloud = ProviderDescriptor(
        id: .yandexcloud,
        displayName: "Yandex Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "俄语区公有云龙头。",
        colorKey: "yandexcloud",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单以 gRPC-only 为主，产品 HTTP 接入模型未覆盖（HOLD）。",
        searchKeywords: ["yandex cloud", "yandex", "grpc"]
    )

    public static let oracleoci = ProviderDescriptor(
        id: .oracleoci,
        displayName: "Oracle Cloud (OCI)",
        kind: .usage,
        category: .hosting,
        tier: .one,
        tierReason: "企业公有云默认短名单之一。",
        colorKey: "oracleoci",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "OSP/Usage 需 RSA 签名与复杂凭据，产品模型未覆盖（HOLD）。",
        searchKeywords: ["oracle", "oci", "oracle cloud", "rsa"]
    )

    public static let pliant = ProviderDescriptor(
        id: .pliant,
        displayName: "Pliant",
        kind: .subscription,
        category: .payments,
        tier: .four,
        tierReason: "企业卡/支出小众方案。",
        colorKey: "pliant",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "KAM/企业开通流程，没有自助公开买家账单 API（HOLD）。",
        searchKeywords: ["pliant", "cards", "spend"]
    )

    public static let atlassian = ProviderDescriptor(
        id: .atlassian,
        displayName: "Atlassian Commerce",
        kind: .subscription,
        category: .devTools,
        tier: .one,
        tierReason: "开发者协作套件企业默认短名单。",
        colorKey: "atlassian",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Commerce 以伙伴/组织门户为主，缺产品可用的自助买家发票 API（HOLD）。",
        searchKeywords: ["atlassian", "jira", "confluence", "commerce"]
    )

    public static let bandwidth = ProviderDescriptor(
        id: .bandwidth,
        displayName: "Bandwidth",
        kind: .usage,
        category: .messaging,
        tier: .two,
        tierReason: "企业通信 CPaaS 强挑战者。",
        colorKey: "bandwidth",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "异步 BDR 导出过重，产品模型未覆盖（HOLD）。",
        searchKeywords: ["bandwidth", "cpaas", "voice", "sms"]
    )

    public static let megaport = ProviderDescriptor(
        id: .megaport,
        displayName: "Megaport",
        kind: .usage,
        category: .networkEdge,
        tier: .two,
        tierReason: "网络互联/云连接强挑战者。",
        colorKey: "megaport",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "账单 schema 不清晰，无法稳定作为期间金额 SoT（HOLD）。",
        searchKeywords: ["megaport", "interconnect", "network"]
    )

    public static let edf = ProviderDescriptor(
        id: .edf,
        displayName: "EDF",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "法国电力零售龙头。",
        colorKey: "edf",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "能源账户 OAuth 缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["edf", "electricity", "france", "电力"]
    )

    public static let eonnext = ProviderDescriptor(
        id: .eonnext,
        displayName: "E.ON Next",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "英国能源零售（E.ON）常见选项。",
        colorKey: "eonnext",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Kraken OAuth 缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["e.on next", "eon next", "kraken", "energy", "电力"]
    )

    public static let engie = ProviderDescriptor(
        id: .engie,
        displayName: "Engie",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "欧洲能源零售/公用事业龙头之一。",
        colorKey: "engie",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "能源账户 OAuth 缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["engie", "energy", "电力", "天然气"]
    )

    public static let vattenfall = ProviderDescriptor(
        id: .vattenfall,
        displayName: "Vattenfall",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "北欧/欧洲能源零售龙头之一。",
        colorKey: "vattenfall",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "能源账户 OAuth 缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["vattenfall", "energy", "电力"]
    )

    public static let britishgas = ProviderDescriptor(
        id: .britishgas,
        displayName: "British Gas",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "英国能源零售默认短名单。",
        colorKey: "britishgas",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Kraken OAuth 缺产品可用凭据字段（HOLD）。",
        searchKeywords: ["british gas", "kraken", "energy", "电力", "天然气"]
    )

    public static let travelperk = ProviderDescriptor(
        id: .travelperk,
        displayName: "TravelPerk",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "商务差旅管理强挑战者。",
        colorKey: "travelperk",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "差旅报销/费用形态，不是买家云服务期间账单 SoT。",
        searchKeywords: ["travelperk", "travel", "差旅"]
    )

    public static let payhawk = ProviderDescriptor(
        id: .payhawk,
        displayName: "Payhawk",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "企业支出卡欧洲中型选手。",
        colorKey: "payhawk",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "企业支出/卡账单形态，不是云服务买家发票 SoT。",
        searchKeywords: ["payhawk", "spend", "cards", "支出"]
    )

    public static let moss = ProviderDescriptor(
        id: .moss,
        displayName: "Moss",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "欧洲企业支出管理中型选手。",
        colorKey: "moss",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "支出管理形态，不是云服务买家发票 SoT。",
        searchKeywords: ["moss", "spend", "支出"]
    )

    public static let soldo = ProviderDescriptor(
        id: .soldo,
        displayName: "Soldo",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "预付企业卡中型选手。",
        colorKey: "soldo",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预付卡/支出形态，不是云服务买家发票 SoT。",
        searchKeywords: ["soldo", "cards", "prepaid", "支出"]
    )

    public static let ramp = ProviderDescriptor(
        id: .ramp,
        displayName: "Ramp",
        kind: .subscription,
        category: .payments,
        tier: .one,
        tierReason: "美国企业卡/支出管理龙头之一。",
        colorKey: "ramp",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "企业支出卡形态，不是云服务买家发票 SoT。",
        searchKeywords: ["ramp", "spend", "cards", "支出"]
    )

    public static let brex = ProviderDescriptor(
        id: .brex,
        displayName: "Brex",
        kind: .subscription,
        category: .payments,
        tier: .one,
        tierReason: "美国创业公司企业卡默认短名单。",
        colorKey: "brex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "企业卡/支出形态，不是云服务买家发票 SoT。",
        searchKeywords: ["brex", "cards", "spend", "支出"]
    )

    public static let hubspot = ProviderDescriptor(
        id: .hubspot,
        displayName: "HubSpot CRM Invoices",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "CRM/营销套件大众市场龙头。",
        colorKey: "hubspot",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "CRM 开票属卖家 AR，不是买家云账单 SoT。",
        searchKeywords: ["hubspot", "crm", "invoices", "卖家开票"]
    )

    public static let shopifypartner = ProviderDescriptor(
        id: .shopifypartner,
        displayName: "Shopify Partner Billing",
        kind: .usage,
        category: .other,
        tier: .one,
        tierReason: "电商平台伙伴生态绝对龙头。",
        colorKey: "shopifypartner",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Partner Billing 属卖家/伙伴分成，不是买家云账单 SoT。",
        searchKeywords: ["shopify", "partner billing", "partners", "卖家"]
    )

    public static let bigcommerce = ProviderDescriptor(
        id: .bigcommerce,
        displayName: "BigCommerce Unified Billing",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "电商平台强挑战者。",
        colorKey: "bigcommerce",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Unified Billing 属平台/卖家侧，不是买家云账单 SoT。",
        searchKeywords: ["bigcommerce", "ecommerce", "卖家"]
    )

    public static let salesforce = ProviderDescriptor(
        id: .salesforce,
        displayName: "Salesforce Revenue Cloud",
        kind: .subscription,
        category: .other,
        tier: .one,
        tierReason: "企业 CRM 绝对龙头。",
        colorKey: "salesforce",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Revenue Cloud 属卖家收入/开票，不是买家云账单 SoT。",
        searchKeywords: ["salesforce", "revenue cloud", "crm", "卖家"]
    )

    public static let servicenow = ProviderDescriptor(
        id: .servicenow,
        displayName: "ServiceNow AP Invoice",
        kind: .subscription,
        category: .other,
        tier: .one,
        tierReason: "企业 ITSM 绝对龙头。",
        colorKey: "servicenow",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "AP Invoice 属应付/采购发票，不是云服务买家用量账单 SoT。",
        searchKeywords: ["servicenow", "ap invoice", "itsm"]
    )

    public static let workday = ProviderDescriptor(
        id: .workday,
        displayName: "Workday",
        kind: .subscription,
        category: .other,
        tier: .one,
        tierReason: "企业 HCM/财务默认短名单。",
        colorKey: "workday",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "财务/应付形态，不是云服务买家用量账单 SoT。",
        searchKeywords: ["workday", "hcm", "finance"]
    )

    public static let rippling = ProviderDescriptor(
        id: .rippling,
        displayName: "Rippling Bill Pay",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "HR/IT 一体化强挑战者。",
        colorKey: "rippling",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Bill Pay 属应付付款，不是云服务买家账单 SoT。",
        searchKeywords: ["rippling", "bill pay", "hr"]
    )

    public static let gusto = ProviderDescriptor(
        id: .gusto,
        displayName: "Gusto Embedded",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "美国中小企业薪资默认短名单之一。",
        colorKey: "gusto",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "Embedded 薪资/卖家侧嵌入，不是买家云账单 SoT。",
        searchKeywords: ["gusto", "payroll", "embedded", "薪资"]
    )

    public static let wefact = ProviderDescriptor(
        id: .wefact,
        displayName: "WeFact",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "荷兰开票/会计中小工具。",
        colorKey: "wefact",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家开票工具，不是买家云账单 SoT。",
        searchKeywords: ["wefact", "invoicing", "netherlands", "卖家开票"]
    )

    public static let lago = ProviderDescriptor(
        id: .lago,
        displayName: "Lago",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "开源用量计费引擎中型选手。",
        colorKey: "lago",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家计费引擎，不是买家云账单 SoT。",
        searchKeywords: ["lago", "billing", "usage metering", "卖家计费"]
    )

    public static let factuarea = ProviderDescriptor(
        id: .factuarea,
        displayName: "Factuarea",
        kind: .subscription,
        category: .other,
        tier: .four,
        tierReason: "开票小众工具。",
        colorKey: "factuarea",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家开票工具，不是买家云账单 SoT。",
        searchKeywords: ["factuarea", "invoicing", "卖家开票"]
    )

    public static let spaceinvoices = ProviderDescriptor(
        id: .spaceinvoices,
        displayName: "Space Invoices",
        kind: .subscription,
        category: .other,
        tier: .four,
        tierReason: "开票 API 小众工具。",
        colorKey: "spaceinvoices",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家开票 API，不是买家云账单 SoT。",
        searchKeywords: ["space invoices", "invoicing", "卖家开票"]
    )

    public static let beel = ProviderDescriptor(
        id: .beel,
        displayName: "Beel",
        kind: .subscription,
        category: .other,
        tier: .four,
        tierReason: "开票/财务小众工具。",
        colorKey: "beel",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家开票形态，不是买家云账单 SoT。",
        searchKeywords: ["beel", "invoicing", "卖家开票"]
    )

    public static let invoiced = ProviderDescriptor(
        id: .invoiced,
        displayName: "Invoiced",
        kind: .subscription,
        category: .payments,
        tier: .three,
        tierReason: "应收开票自动化中型选手。",
        colorKey: "invoiced",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家 AR 开票，不是买家云账单 SoT。",
        searchKeywords: ["invoiced", "ar", "invoicing", "卖家开票"]
    )

    public static let moneybird = ProviderDescriptor(
        id: .moneybird,
        displayName: "Moneybird",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "荷兰中小会计/开票常见选项。",
        colorKey: "moneybird",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家会计开票，不是买家云账单 SoT。",
        searchKeywords: ["moneybird", "accounting", "netherlands", "卖家开票"]
    )

    public static let economic = ProviderDescriptor(
        id: .economic,
        displayName: "e-conomic",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "丹麦中小会计常见选项（Visma）。",
        colorKey: "economic",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家会计开票，不是买家云账单 SoT。",
        searchKeywords: ["e-conomic", "economic", "visma", "accounting", "卖家开票"]
    )

    public static let tripletex = ProviderDescriptor(
        id: .tripletex,
        displayName: "Tripletex",
        kind: .subscription,
        category: .other,
        tier: .three,
        tierReason: "挪威中小会计常见选项。",
        colorKey: "tripletex",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家会计开票，不是买家云账单 SoT。",
        searchKeywords: ["tripletex", "accounting", "norway", "卖家开票"]
    )

    public static let fortnox = ProviderDescriptor(
        id: .fortnox,
        displayName: "Fortnox",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "瑞典中小会计龙头之一。",
        colorKey: "fortnox",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家会计开票，不是买家云账单 SoT。",
        searchKeywords: ["fortnox", "accounting", "sweden", "卖家开票"]
    )

    public static let visma = ProviderDescriptor(
        id: .visma,
        displayName: "Visma",
        kind: .subscription,
        category: .other,
        tier: .one,
        tierReason: "北欧企业财务/ERP 默认短名单。",
        colorKey: "visma",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "卖家 ERP/开票，不是买家云账单 SoT。",
        searchKeywords: ["visma", "erp", "accounting", "卖家开票"]
    )

    public static let fyatu = ProviderDescriptor(
        id: .fyatu,
        displayName: "Fyatu",
        kind: .prepaid,
        category: .messaging,
        tier: .four,
        tierReason: "预付通信/虚拟号码小众商。",
        colorKey: "fyatu",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预付费余额模型，不是期间买家发票 SoT。",
        searchKeywords: ["fyatu", "prepaid", "sms", "预付费"]
    )

    public static let smsglobal = ProviderDescriptor(
        id: .smsglobal,
        displayName: "SMSGlobal",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "短信网关中小厂商。",
        colorKey: "smsglobal",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预付费/卖家侧余额形态，不是期间买家发票 SoT。",
        searchKeywords: ["smsglobal", "sms", "prepaid"]
    )

    public static let burstsms = ProviderDescriptor(
        id: .burstsms,
        displayName: "BurstSMS",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "短信网关中小厂商（Transmitsms）。",
        colorKey: "burstsms",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "预付费余额模型，不是期间买家发票 SoT。",
        searchKeywords: ["burstsms", "transmit sms", "sms", "prepaid"]
    )

    public static let serverspace = ProviderDescriptor(
        id: .serverspace,
        displayName: "Serverspace",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "国际 VPS 小众云商。",
        colorKey: "serverspace",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开能力偏卖家/控制台，缺少可用买家期间发票 API。",
        searchKeywords: ["serverspace", "vps", "cloud"]
    )

    public static let tilaa = ProviderDescriptor(
        id: .tilaa,
        displayName: "Tilaa",
        kind: .usage,
        category: .hosting,
        tier: .four,
        tierReason: "荷兰 VPS 小众商。",
        colorKey: "tilaa",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "公开能力不足以构成买家期间发票 SoT。",
        searchKeywords: ["tilaa", "vps", "netherlands"]
    )

    public static let qonto = ProviderDescriptor(
        id: .qonto,
        displayName: "Qonto",
        kind: .subscription,
        category: .payments,
        tier: .two,
        tierReason: "欧洲新银行/商务账户强挑战者。",
        colorKey: "qonto",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "subscription list 仅标价，不是已发生买家账单合计。",
        searchKeywords: ["qonto", "banking", "neobank", "标价"]
    )

    public static let factorial = ProviderDescriptor(
        id: .factorial,
        displayName: "Factorial",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "欧洲 HR 软件强挑战者。",
        colorKey: "factorial",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "费用/HR 报销形态，不是云服务买家账单 SoT。",
        searchKeywords: ["factorial", "hr", "expense", "报销"]
    )

    public static let personio = ProviderDescriptor(
        id: .personio,
        displayName: "Personio",
        kind: .subscription,
        category: .other,
        tier: .two,
        tierReason: "欧洲 HR 软件强挑战者。",
        colorKey: "personio",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "费用/HR 报销形态，不是云服务买家账单 SoT。",
        searchKeywords: ["personio", "hr", "expense", "报销"]
    )

    public static let pandadoc = ProviderDescriptor(
        id: .pandadoc,
        displayName: "PandaDoc",
        kind: .subscription,
        category: .collaboration,
        tier: .two,
        tierReason: "提案/电子签强挑战者。",
        colorKey: "pandadoc",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["pandadoc", "esign", "proposals", "电子签"]
    )

    public static let dropboxsign = ProviderDescriptor(
        id: .dropboxsign,
        displayName: "Dropbox Sign",
        kind: .subscription,
        category: .collaboration,
        tier: .one,
        tierReason: "电子签名默认短名单之一（原 HelloSign）。",
        colorKey: "dropboxsign",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "仅门户账单，没有公开买家发票金额 API。",
        searchKeywords: ["dropbox sign", "hellosign", "esign", "电子签"]
    )

    public static let adobevip = ProviderDescriptor(
        id: .adobevip,
        displayName: "Adobe VIP",
        kind: .subscription,
        category: .other,
        tier: .one,
        tierReason: "创意软件企业采购默认短名单。",
        colorKey: "adobevip",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "VIP 伙伴门户许可，不是自助买家云账单 API。",
        searchKeywords: ["adobe", "vip", "creative cloud", "伙伴门户"]
    )

    public static let spendesk = ProviderDescriptor(
        id: .spendesk,
        displayName: "Spendesk",
        kind: .subscription,
        category: .payments,
        tier: .two,
        tierReason: "欧洲企业支出管理强挑战者。",
        colorKey: "spendesk",
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .declined,
        declineReason: "企业支出管理形态，不是云服务买家发票 SoT。",
        searchKeywords: ["spendesk", "spend", "expense", "支出"]
    )
}
