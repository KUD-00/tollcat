import Foundation
import MeterCore

extension ProviderCatalog {
    public static let paypal = ProviderDescriptor(
        id: .paypal,
        displayName: "PayPal",
        kind: .usage,
        category: .payments,
        tier: .one,
        tierReason: "全球收单与钱包的收入寡头，商户支付基建短名单核心。",
        colorKey: "paypal",
        billingURL: URL(string: "https://www.paypal.com/")!,
        credentialSetupURL: URL(string: "https://developer.paypal.com/docs/api/transaction-search/v1/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 1,
        accessStatus: .pendingVerification,
        searchKeywords: ["paypal", "fee_amount", "reporting/transactions", "client credentials"]
    )

    public static let paystack = ProviderDescriptor(
        id: .paystack,
        displayName: "Paystack",
        kind: .usage,
        category: .payments,
        tier: .two,
        tierReason: "非洲收单的强挑战者，与 Flutterwave 并列区域支付基建短名单。",
        colorKey: "paystack",
        billingURL: URL(string: "https://dashboard.paystack.com/")!,
        credentialSetupURL: URL(string: "https://paystack.com/docs/api/transaction/#list")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["paystack", "fees", "transaction", "NGN", "secret key"]
    )

    public static let flutterwave = ProviderDescriptor(
        id: .flutterwave,
        displayName: "Flutterwave",
        kind: .usage,
        category: .payments,
        tier: .two,
        tierReason: "非洲收单的强挑战者，与 Paystack 并列区域支付基建短名单。",
        colorKey: "flutterwave",
        billingURL: URL(string: "https://dashboard.flutterwave.com/")!,
        credentialSetupURL: URL(string: "https://developer.flutterwave.com/docs/transaction-verification")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["flutterwave", "app_fee", "transactions", "secret key"]
    )
}
