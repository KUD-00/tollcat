#if DEBUG
import Foundation
import MeterCore
import MeterFormat
import MeterModules
import MeterProviders

/// 设计稿那组数字（SPEC 第 04 节），实验室在当前账本缺某一块时拿来填。
/// 只构造值对象，不碰 store。
enum DashboardLabFixtures {
    static let contents: DashboardContents = make()

    private static func make() -> DashboardContents {
        DashboardContents(
            monthToDateContent: GalleryFixtures.monthToDateContent(
                amount: Money(roundedUSD: 47.20),
                projected: Money(roundedUSD: 87.70),
                confidence: .estimated,
                estimatedNames: ["Neon"]
            ),
            compositionContent: composition,
            anomalyContent: GalleryFixtures.anomaly([
                (.aws, 0.62),
                (.openai, 0.41),
                (.cloudflare, 0.33),
            ]),
            balanceAlertContent: BalanceAlertModuleContent(items: [
                BalanceAlertItem(
                    accountID: AccountID.fixture(for: .openai),
                    providerID: .openai,
                    displayName: "OpenAI",
                    colorKey: "openai",
                    balanceUSD: Money(usd: 42),
                    daysRemaining: 18
                ),
            ]),
            upcomingChargesContent: UpcomingChargesModuleContent(items: [
                UpcomingChargeItem(
                    id: "chatgpt",
                    accountID: AccountID.fixture(for: .openai),
                    providerID: .openai,
                    displayName: "ChatGPT Plus",
                    colorKey: "openai",
                    amount: Money(usd: 20),
                    chargeDate: Date(timeIntervalSince1970: 0),
                    dateCaption: String(localized: L("8 月 20 日"))
                ),
            ]),
            freeQuotaContent: FreeQuotaModuleContent(items: [
                FreeQuotaItem(
                    accountID: AccountID.fixture(for: .vercel),
                    providerID: .vercel,
                    displayName: "Vercel",
                    colorKey: "vercel",
                    usedRatio: 0.34
                ),
                FreeQuotaItem(
                    accountID: AccountID.fixture(for: .github),
                    providerID: .github,
                    displayName: "GitHub",
                    colorKey: "github",
                    usedRatio: 0.84
                ),
            ]),
            servicesContent: services,
            subscriptionsContent: SubscriptionsPreviewData.sample,
            heatmapContent: HeatmapPreviewData.sample,
            categoriesContent: CategoriesPreviewData.sample,
            superlativesContent: SuperlativesPreviewData.sample,
            budgetContent: BudgetPreviewData.sample
        )
    }

    /// 五家才看得出宽卡分两列。金额是 SPEC 第 04 节那组。
    private static let services = ServicesModuleContent(items: [
        service(.aws, name: "AWS", amount: 21.40, change: "+62%", up: true, spark: [12, 14, 13, 16, 19, 21]),
        service(.cloudflare, name: "Cloudflare", amount: 11.05, change: "+12%", up: true, spark: [6, 8, 7, 9, 10, 11]),
        service(.openai, name: "OpenAI", amount: 7.62, change: nil, up: false, spark: [4, 5, 5, 6, 7, 7.6]),
        service(.github, name: "GitHub", amount: 4.00, change: nil, up: false, spark: [4, 4, 4, 4, 4, 4]),
        service(.neon, name: "Neon", amount: 3.13, change: nil, up: false, spark: [0, 0, 2, 3, 3, 3.1]),
    ])

    private static let composition = CompositionModuleContent(
        segments: [
            segment(.aws, amount: 21.40, fraction: 0.4534, percent: 45),
            segment(.cloudflare, amount: 11.05, fraction: 0.2341, percent: 23),
            segment(.openai, amount: 7.62, fraction: 0.1614, percent: 16),
            segment(.github, amount: 4.00, fraction: 0.0847, percent: 9),
            segment(.neon, amount: 3.13, fraction: 0.0663, percent: 7),
        ],
        totalText: Money(roundedUSD: 47.20).formatted(),
        spokenTotal: SpokenMoney.label(for: Money(roundedUSD: 47.20)),
        destination: AccountID.fixture(for: .aws)
    )

    private static func segment(
        _ id: ProviderID,
        amount: Double,
        fraction: Double,
        percent: Int
    ) -> CompositionSegment {
        let descriptor = ProviderCatalog.descriptor(id: id)
        return CompositionSegment(
            accountID: AccountID.fixture(for: id),
            providerID: id,
            displayName: descriptor?.displayName ?? id.rawValue,
            colorKey: descriptor?.colorKey ?? id.rawValue,
            amount: Money(roundedUSD: amount),
            fraction: fraction,
            percent: percent
        )
    }

    private static func service(
        _ id: ProviderID,
        name: String,
        amount: Double,
        change: String?,
        up: Bool,
        spark: [Double]
    ) -> ServiceCardItem {
        let descriptor = ProviderCatalog.descriptor(id: id)
        return ServiceCardItem(
            accountID: AccountID.fixture(for: id),
            providerID: id,
            displayName: name,
            colorKey: descriptor?.colorKey ?? id.rawValue,
            amountText: Money(roundedUSD: amount).formatted(),
            amountValue: amount,
            spokenAmount: SpokenMoney.label(for: Money(roundedUSD: amount)),
            changeText: change,
            changeIsUp: up,
            spark: spark
        )
    }
}
#endif
