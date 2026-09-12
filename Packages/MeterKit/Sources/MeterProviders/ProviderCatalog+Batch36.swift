import Foundation
import MeterCore

extension ProviderCatalog {
    public static let fiskil = ProviderDescriptor(
        id: .fiskil,
        displayName: "Fiskil",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "澳洲 CDR 能源发票聚合（total_amount+currency），体量小于 UtilityAPI / VoltView 同类短名单。",
        colorKey: "fiskil",
        billingURL: URL(string: "https://fiskil.com/")!,
        credentialSetupURL: URL(string: "https://console.fiskil.com/data-api/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["fiskil", "cdr", "energy", "invoice", "AUD", "total_amount"]
    )

    public static let threeplguys = ProviderDescriptor(
        id: .threeplguys,
        displayName: "3PLGuys",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "北美电商履约/仓储 3PL 的细分选手，买方发票 totalAmount（分）+currency，与 ShipBob 同属履约账单短名单。",
        colorKey: "threeplguys",
        billingURL: URL(string: "https://3plguys.com/")!,
        credentialSetupURL: URL(string: "https://developer.3plguys.com/docs/invoices/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["3plguys", "3pl", "fulfillment", "invoices", "totalAmount", "USD"]
    )

    public static let pleo = ProviderDescriptor(
        id: .pleo,
        displayName: "Pleo",
        kind: .usage,
        category: .other,
        tier: .two,
        tierReason: "欧洲企业支出卡 SaaS 的强挑战者；仅取 PLEO_INVOICE（买方平台费）minors+currency，排除报销/卡消费聚合。",
        colorKey: "pleo",
        billingURL: URL(string: "https://www.pleo.io/")!,
        credentialSetupURL: URL(string: "https://app.pleo.io/settings/api-keys")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: true,
        historyLookbackMonths: 12,
        accessStatus: .pendingVerification,
        searchKeywords: ["pleo", "PLEO_INVOICE", "accounting-entries", "minors", "EUR"]
    )
}
