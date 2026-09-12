import Foundation
import MeterCore

extension ProviderCatalog {
    public static let gelato = ProviderDescriptor(
        id: .gelato,
        displayName: "Gelato",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "按需印刷与全球履约的强挑战者，与 Printful 等同台。",
        colorKey: "gelato",
        billingURL: URL(string: "https://dashboard.gelato.com/")!,
        credentialSetupURL: URL(string: "https://dashboard.gelato.com/apis/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["gelato", "print on demand", "pod"]
    )

    public static let prodigi = ProviderDescriptor(
        id: .prodigi,
        displayName: "Prodigi",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "按需印刷 API 细分里的欧洲选手。",
        colorKey: "prodigi",
        billingURL: URL(string: "https://www.prodigi.com/")!,
        credentialSetupURL: URL(string: "https://dashboard.prodigi.com/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["prodigi", "print api", "pod"]
    )

    public static let qiniu = ProviderDescriptor(
        id: .qiniu,
        displayName: "Qiniu",
        kind: .usage,
        category: .storage,
        tier: .two,
        tierReason: "中国对象存储与 CDN 的强挑战者，份额次于阿里云等巨头。",
        colorKey: "qiniu",
        billingURL: URL(string: "https://portal.qiniu.com/")!,
        credentialSetupURL: URL(string: "https://developer.qiniu.com/kodo/1201/access-key")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["qiniu", "七牛", "七牛云", "kodo"]
    )

    public static let mysendingbox = ProviderDescriptor(
        id: .mysendingbox,
        displayName: "MySendingBox",
        kind: .usage,
        category: .messaging,
        tier: .three,
        tierReason: "法国实体信函 API 细分里的小型选手。",
        colorKey: "mysendingbox",
        billingURL: URL(string: "https://www.mysendingbox.fr/")!,
        credentialSetupURL: URL(string: "https://app.mysendingbox.fr/account/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["mysendingbox", "my sending box", "courrier", "lettre"]
    )

    public static let stannp = ProviderDescriptor(
        id: .stannp,
        displayName: "Stannp",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "英国直邮/明信片 API 细分里的小型选手。",
        colorKey: "stannp",
        billingURL: URL(string: "https://www.stannp.com/")!,
        credentialSetupURL: URL(string: "https://dash.stannp.com")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["stannp", "direct mail", "postcard"]
    )

    public static let phaxio = ProviderDescriptor(
        id: .phaxio,
        displayName: "Phaxio",
        kind: .prepaid,
        category: .messaging,
        tier: .three,
        tierReason: "开发者传真 API 细分里的小型选手。",
        colorKey: "phaxio",
        billingURL: URL(string: "https://www.phaxio.com/")!,
        credentialSetupURL: URL(string: "https://www.phaxio.com/apiSettings")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["phaxio", "fax", "fax api"]
    )

    public static let porkbun = ProviderDescriptor(
        id: .porkbun,
        displayName: "Porkbun",
        kind: .prepaid,
        category: .networkEdge,
        tier: .three,
        tierReason: "低价域名注册商里的活跃挑战者，份额小于 GoDaddy/Namecheap。",
        colorKey: "porkbun",
        billingURL: URL(string: "https://porkbun.com/")!,
        credentialSetupURL: URL(string: "https://porkbun.com/account/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["porkbun", "domain", "dns"]
    )

    public static let namecheap = ProviderDescriptor(
        id: .namecheap,
        displayName: "Namecheap",
        kind: .prepaid,
        category: .networkEdge,
        tier: .two,
        tierReason: "大众域名注册的强挑战者，长期与 GoDaddy 争夺中小客户。",
        colorKey: "namecheap",
        billingURL: URL(string: "https://www.namecheap.com/")!,
        credentialSetupURL: URL(string: "https://ap.www.namecheap.com/settings/tools/apiaccess/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["namecheap", "domain", "dns"]
    )

    public static let gandi = ProviderDescriptor(
        id: .gandi,
        displayName: "Gandi",
        kind: .prepaid,
        category: .networkEdge,
        tier: .three,
        tierReason: "欧洲域名与简易主机的传统选手，份额持续被挤压。",
        colorKey: "gandi",
        billingURL: URL(string: "https://admin.gandi.net/")!,
        credentialSetupURL: URL(string: "https://admin.gandi.net/organizations/account/pat")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["gandi", "domain", "dns", "gandinet"]
    )
}
