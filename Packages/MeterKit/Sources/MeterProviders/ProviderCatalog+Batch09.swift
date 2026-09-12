import Foundation
import MeterCore

extension ProviderCatalog {
    public static let shipstation = ProviderDescriptor(
        id: .shipstation,
        displayName: "ShipStation",
        kind: .prepaid,
        category: .other,
        tier: .two,
        tierReason: "电商出货/多承运商平台的强挑战者，北美中小卖家常用。",
        colorKey: "shipstation",
        billingURL: URL(string: "https://www.shipstation.com/")!,
        credentialSetupURL: URL(string: "https://docs.shipstation.com/apis/shipengine/docs/getting-started")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["shipstation", "shipengine", "shipping", "label"]
    )

    public static let thanksio = ProviderDescriptor(
        id: .thanksio,
        displayName: "thanks.io",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "实体感谢卡/直邮 API 细分里的小型选手。",
        colorKey: "thanksio",
        billingURL: URL(string: "https://www.thanks.io/")!,
        credentialSetupURL: URL(string: "https://docs.thanks.io/authentication/bearer-token")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        accessStatus: .pendingVerification,
        searchKeywords: ["thanks.io", "thanksio", "postcard", "direct mail"]
    )

    public static let click2mail = ProviderDescriptor(
        id: .click2mail,
        displayName: "Click2Mail",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "美国商务直邮 API 细分里的区域选手。",
        colorKey: "click2mail",
        billingURL: URL(string: "https://www.click2mail.com/")!,
        credentialSetupURL: URL(string: "https://developers.click2mail.com/docs/building-your-first-api-call")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        accessStatus: .pendingVerification,
        searchKeywords: ["click2mail", "click 2 mail", "direct mail", "postal"]
    )
}
