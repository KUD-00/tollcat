import Foundation
import MeterCore

extension ProviderCatalog {
    public static let conoha = ProviderDescriptor(
        id: .conoha,
        displayName: "ConoHa",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "日本主机市场的挑战者，面向个人与中小团队。",
        colorKey: "conoha",
        billingURL: URL(string: "https://www.conoha.jp/")!,
        credentialSetupURL: URL(string: "https://doc.conoha.jp/reference/api-vps2/api-account-vps2/account-billing-invoices-list-v2/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["conoha", "gmo", "billing-invoices", "bill_plas_tax", "tyo1", "日本"]
    )

    public static let zcomcloud = ProviderDescriptor(
        id: .zcomcloud,
        displayName: "Z.com Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "GMO 国际云/VPS 品牌，日本与亚太主机市场的挑战者。",
        colorKey: "zcomcloud",
        billingURL: URL(string: "https://cloud.z.com/")!,
        credentialSetupURL: URL(string: "https://cloud.z.com/jp/guide/cp-create_api_user/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["z.com", "zcom", "gmo", "billing-invoices", "bill_plas_tax", "tyo1"],
        guideURLs: [
            "findTenant": URL(string: "https://cloud.z.com/jp/guide/cp-get_api_info/")!,
        ]
    )

    public static let idcf = ProviderDescriptor(
        id: .idcf,
        displayName: "IDCF Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "日本主权云/IDC 的区域选手，面向国内企业，远小于 Hyperscaler。",
        colorKey: "idcf",
        billingURL: URL(string: "https://www.idcf.jp/")!,
        credentialSetupURL: URL(string: "https://console.idcfcloud.com/user/apikey")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["idcf", "idc frontier", "billings", "your.idcfcloud.com", "JPY"]
    )

    public static let internetx = ProviderDescriptor(
        id: .internetx,
        displayName: "InterNetX",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "欧洲域名注册/AutoDNS 细分里的德国选手。",
        colorKey: "internetx",
        billingURL: URL(string: "https://www.internetx.com/")!,
        credentialSetupURL: URL(string: "https://help.internetx.com/display/APIXMLEN/Authentication")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["internetx", "autodns", "invoice", "domainrobot", "EUR"]
    )

    public static let melbicom = ProviderDescriptor(
        id: .melbicom,
        displayName: "Melbicom",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "欧洲独立服务器与 CDN 的区域选手，体量小于西欧主流 IaaS。",
        colorKey: "melbicom",
        billingURL: URL(string: "https://www.melbicom.net/")!,
        credentialSetupURL: URL(string: "https://docs.api.melbicom.net/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["melbicom", "billing/invoices", "cdn", "dedicated", "USD"]
    )
}
