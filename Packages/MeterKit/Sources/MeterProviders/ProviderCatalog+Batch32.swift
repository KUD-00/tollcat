import Foundation
import MeterCore

extension ProviderCatalog {
    public static let filescom = ProviderDescriptor(
        id: .filescom,
        displayName: "Files.com",
        kind: .usage,
        category: .storage,
        tier: .three,
        tierReason: "企业文件传输/对象存储 period 发票（amount+currency），体量小于 Backblaze / Wasabi。",
        colorKey: "filescom",
        billingURL: URL(string: "https://www.files.com/")!,
        credentialSetupURL: URL(string: "https://developers.files.com/rest/resources/billing/account-line-items/")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["files.com", "filescom", "invoice", "storage", "sftp"]
    )

    public static let doit = ProviderDescriptor(
        id: .doit,
        displayName: "DoiT",
        kind: .usage,
        category: .other,
        tier: .three,
        tierReason: "多云 FinOps 发票列表（totalAmount），体量小于原生 AWS / GCP 账单适配。",
        colorKey: "doit",
        billingURL: URL(string: "https://www.doit.com/")!,
        credentialSetupURL: URL(string: "https://developer.doit.com/docs/invoice")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["doit", "doit.com", "finops", "invoice", "aws", "gcp"]
    )

    public static let timeweb = ProviderDescriptor(
        id: .timeweb,
        displayName: "Timeweb Cloud",
        kind: .usage,
        category: .hosting,
        tier: .three,
        tierReason: "俄罗斯区域云 finances.monthly_cost+currency，体量远小于 Selectel / Yandex Cloud。",
        colorKey: "timeweb",
        billingURL: URL(string: "https://timeweb.cloud/")!,
        credentialSetupURL: URL(string: "https://timeweb.cloud/api-docs")!,
        costsMoneyToRefresh: false,
        supportsDailyGranularity: false,
        historyLookbackMonths: 24,
        accessStatus: .pendingVerification,
        searchKeywords: ["timeweb", "timeweb.cloud", "monthly_cost", "finances", "RU"]
    )

}
