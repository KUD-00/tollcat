import Foundation
import MeterCore

extension ProviderCatalog {
    public static let bring = ProviderDescriptor(
        id: .bring,
        displayName: "Bring",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "北欧邮政/包裹物流的强挑战者，挪威与北欧电商物流短名单。",
        colorKey: "bring",
        billingURL: URL(string: "https://www.mybring.com/")!,
        credentialSetupURL: URL(string: "https://www.mybring.com/useradmin/account/settings/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["bring", "posten", "mybring", "invoice", "NOK", "customerNumber"]
    )

    public static let armada = ProviderDescriptor(
        id: .armada,
        displayName: "Armada Delivery",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "中东即时配送平台的细分选手，体量小于全球货运 TMS 短名单。",
        colorKey: "armada",
        billingURL: URL(string: "https://www.armadadelivery.com/")!,
        credentialSetupURL: URL(string: "https://business.armadadelivery.com")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["armada", "delivery", "REGULAR", "invoice", "HMAC", "KWD"]
    )

    public static let mollie = ProviderDescriptor(
        id: .mollie,
        displayName: "Mollie",
        kind: .usage,
        category: .payments,
        tier: .two,
        tierReason: "欧洲支付收单的强挑战者，与 Stripe / Adyen 并列商户支付基建短名单。",
        colorKey: "mollie",
        billingURL: URL(string: "https://my.mollie.com/")!,
        credentialSetupURL: URL(string: "https://my.mollie.com/dashboard/developers/api-access-tokens")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["mollie", "invoices", "grossAmount", "access token", "EUR"]
    )

    public static let checkout = ProviderDescriptor(
        id: .checkout,
        displayName: "Checkout.com",
        kind: .usage,
        category: .payments,
        tier: .two,
        tierReason: "全球收单的强挑战者，与 Stripe / Mollie / Adyen 并列商户支付基建短名单。",
        colorKey: "checkout",
        billingURL: URL(string: "https://dashboard.checkout.com/")!,
        credentialSetupURL: URL(string: "https://dashboard.checkout.com/developers/keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["checkout", "checkout.com", "statements", "processing_fees", "secret key"]
    )

    public static let printify = ProviderDescriptor(
        id: .printify,
        displayName: "Printify",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "按需印刷 POD 的强挑战者，与 Printful / Gelato 并列电商履约短名单。",
        colorKey: "printify",
        billingURL: URL(string: "https://printify.com/")!,
        credentialSetupURL: URL(string: "https://printify.com/app/account/api")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["printify", "POD", "orders", "cost", "shop_id", "cents"],
        guideURLs: [
            "findShopID": URL(string: "https://developers.printify.com/#retrieving-shop-id")!,
        ]
    )

    public static let teelaunch = ProviderDescriptor(
        id: .teelaunch,
        displayName: "teelaunch",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "北美 POD 履约的细分选手，体量小于 Printful / Printify 短名单。",
        colorKey: "teelaunch",
        billingURL: URL(string: "https://teelaunch.com/")!,
        credentialSetupURL: URL(string: "https://api.teelaunch.com/documentation")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["teelaunch", "payment-history", "amount", "POD", "JWT"]
    )
}
