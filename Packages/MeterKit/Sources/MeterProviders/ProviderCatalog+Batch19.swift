import Foundation
import MeterCore

extension ProviderCatalog {
    public static let shipbob = ProviderDescriptor(
        id: .shipbob,
        displayName: "ShipBob",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "美国电商履约/仓储物流（3PL）的强挑战者，与大型履约网络并列短名单。",
        colorKey: "shipbob",
        billingURL: URL(string: "https://web.shipbob.com")!,
        credentialSetupURL: URL(string: "https://developer.shipbob.com/guides/billing")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["shipbob", "ship bob", "fulfillment", "wms", "invoices", "billing_read"]
    )

    public static let mikrocloud = ProviderDescriptor(
        id: .mikrocloud,
        displayName: "MikroCloud",
        kind: .usage,
        category: .networkEdge,
        tier: .three,
        tierReason: "MikroTik 设备云管平台的细分选手，体量小于主流网络/物联网云。",
        colorKey: "mikrocloud",
        billingURL: URL(string: "https://mikrocloud.com")!,
        credentialSetupURL: URL(string: "https://docs.mikrocloud.com/api/accounts/invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["mikrocloud", "mikrotik", "invoice", "account invoices"]
    )

    public static let leaseweb = ProviderDescriptor(
        id: .leaseweb,
        displayName: "Leaseweb",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "全球裸金属/托管主机的强挑战者，欧洲与北美机房网络成熟。",
        colorKey: "leaseweb",
        billingURL: URL(string: "https://secure.leaseweb.com")!,
        credentialSetupURL: URL(string: "https://developer.leaseweb.com/api-docs/invoice_v1.html")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["leaseweb", "invoice", "X-LSW-Auth", "bare metal"]
    )

    public static let qovery = ProviderDescriptor(
        id: .qovery,
        displayName: "Qovery",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "Kubernetes 部署/开发环境 PaaS 的细分选手，体量小于 Railway/Render 主流替代短名单。",
        colorKey: "qovery",
        billingURL: URL(string: "https://console.qovery.com")!,
        credentialSetupURL: URL(string: "https://www.qovery.com/docs/api-reference/openapi.yaml")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["qovery", "invoice", "organization invoice", "kubernetes"]
    )

    public static let phoenixnap = ProviderDescriptor(
        id: .phoenixnap,
        displayName: "phoenixNAP",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "全球裸金属/边缘机房的强挑战者，欧美机房网络成熟。",
        colorKey: "phoenixnap",
        billingURL: URL(string: "https://bmc.phoenixnap.com")!,
        credentialSetupURL: URL(string: "https://developers.phoenixnap.com/docs/invoicing/1/overview")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["phoenixnap", "phoenix nap", "bmc", "invoices", "bare metal"]
    )

    public static let magalucloud = ProviderDescriptor(
        id: .magalucloud,
        displayName: "Magalu Cloud",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "巴西本土公有云的强挑战者，拉美市场渗透高于多数国际云。",
        colorKey: "magalucloud",
        billingURL: URL(string: "https://console.magalu.cloud")!,
        credentialSetupURL: URL(string: "https://docs.magalu.cloud/api/consumption")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["magalu", "magalu cloud", "magazine luiza", "FOCUS", "BilledCost", "BRL"]
    )


    public static let transip = ProviderDescriptor(
        id: .transip,
        displayName: "TransIP",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "荷兰域名/VPS 区域主机的细分选手，体量小于全球裸金属短名单。",
        colorKey: "transip",
        billingURL: URL(string: "https://www.transip.nl/cp/")!,
        credentialSetupURL: URL(string: "https://api.transip.nl/rest/docs.html#invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["transip", "invoice", "totalAmount", "EUR", "vps", "domain"]
    )

    public static let serverscom = ProviderDescriptor(
        id: .serverscom,
        displayName: "Servers.com",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "全球裸金属/托管主机的强挑战者，与 Leaseweb / phoenixNAP 并列短名单。",
        colorKey: "serverscom",
        billingURL: URL(string: "https://portal.servers.com/")!,
        credentialSetupURL: URL(string: "https://www.servers.com/docs/api-reference/invoice/list-invoices/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["servers.com", "serverscom", "billing invoices", "total_due", "bare metal"]
    )

    public static let flexport = ProviderDescriptor(
        id: .flexport,
        displayName: "Flexport",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "全球货运代理/供应链平台的强挑战者，跨境物流数字化短名单。",
        colorKey: "flexport",
        billingURL: URL(string: "https://app.flexport.com/")!,
        credentialSetupURL: URL(string: "https://developers.flexport.com/tutorials/freight-invoices-api-tutorial/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["flexport", "freight", "invoices", "currency_code", "logistics"]
    )


    public static let i3dnet = ProviderDescriptor(
        id: .i3dnet,
        displayName: "i3D.net",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "荷兰游戏/裸金属主机的细分选手，与 TransIP 同属荷兰区域主机短名单。",
        colorKey: "i3dnet",
        billingURL: URL(string: "https://www.i3d.net/")!,
        credentialSetupURL: URL(string: "https://docs.i3d.net/api-references/general/billing.md")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["i3d", "i3dnet", "invoice", "amountIncVAT", "PRIVATE-TOKEN", "netherlands"]
    )

    public static let datapacket = ProviderDescriptor(
        id: .datapacket,
        displayName: "DataPacket",
        kind: .usage,
        category: .hosting,
        tier: .two,
        tierReason: "欧洲专用服务器/高带宽托管的强挑战者，与 Leaseweb / Servers.com 并列短名单。",
        colorKey: "datapacket",
        billingURL: URL(string: "https://www.datapacket.com/")!,
        credentialSetupURL: URL(string: "https://api.datapacket.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["datapacket", "graphql", "invoices", "dedicated", "bare metal"]
    )

    public static let cudocompute = ProviderDescriptor(
        id: .cudocompute,
        displayName: "CUDO Compute",
        kind: .usage,
        category: .gpuCompute,
        tier: .three,
        tierReason: "分布式 GPU 云的细分选手，体量小于 RunPod / Vast.ai 主流短名单。",
        colorKey: "cudocompute",
        billingURL: URL(string: "https://www.cudocompute.com/")!,
        credentialSetupURL: URL(string: "https://docs.cudocompute.com/api/billing/list-invoices")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["cudo", "cudocompute", "gpu", "invoices", "billing account"]
    )

    public static let shipwell = ProviderDescriptor(
        id: .shipwell,
        displayName: "Shipwell",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "北美货运 TMS/结算平台的强挑战者，与 Flexport 并列物流数字化短名单。",
        colorKey: "shipwell",
        billingURL: URL(string: "https://shipwell.com/")!,
        credentialSetupURL: URL(string: "https://docs.shipwell.com/openapi_pages/settlements/operation/list_freight_invoices/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["shipwell", "freight-invoices", "TMS", "logistics", "settlements"]
    )


    public static let ocamba = ProviderDescriptor(
        id: .ocamba,
        displayName: "Ocamba",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "互动推送/广告变现平台的细分选手，账单 API 清晰但体量小于 Klaviyo 等主流营销云。",
        colorKey: "ocamba",
        billingURL: URL(string: "https://docs.ocamba.com/")!,
        credentialSetupURL: URL(string: "https://docs.ocamba.com/api/core/v2.0/reference/view-invoices/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["ocamba", "push", "invoices", "currency_code", "engagement"]
    )

}
