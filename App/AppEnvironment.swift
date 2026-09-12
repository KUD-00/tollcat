import Foundation
import Observation
import MeterCore
import MeterFeatures
import MeterInbox
import MeterPersistence
import MeterProviders
import MeterUsage

/// Composition root —— 整个 App 里唯一 new 具体实现的地方。
@MainActor
@Observable
final class AppEnvironment {
    let dashboardModel: DashboardModel
    let persistenceStatus: PersistenceStatus
    let settingsModel: SettingsModel
    let usageAnalytics: any UsageAnalyticsRecording

    static func live() -> AppEnvironment {
        AppEnvironment()
    }

    private init() {
        let clock = FeatureLaunchArguments.usesDesignClock ? MeterClock.design : MeterClock.live
        let bootstrap = PersistenceBootstrap.makeLive()
        let bump: Decimal? = FeatureLaunchArguments.meterRefreshBump ? 5 : nil
        let catalogResolver = FeatureLaunchArguments.stubCatalog
            ? CatalogResolver.bundledOnly()
            : CatalogResolver.live()
        let rateSource = SharedExchangeRates(catalogResolver.current().exchangeRates)
        #if DEBUG
        let httpClient: any HTTPClient = InspectingHTTPClient(wrapping: LiveHTTPTransport.make())
        #else
        let httpClient = LiveHTTPTransport.make()
        #endif
        let providers = Self.makeProviders(
            clock: clock,
            refreshBumpUSD: bump,
            rateSource: rateSource,
            httpClient: httpClient
        )
        if bootstrap.shouldSeed {
            try? DashboardFixtureSeeder.seedBlocking(
                into: bootstrap.container,
                credentials: bootstrap.credentials,
                clock: clock
            )
        }
        // 先建提示、再建仪表：仪表读库失败时要往这里报，不能自己再攒一份错误状态。
        let status = PersistenceStatus(
            storage: bootstrap.storage,
            containsDemoData: false,
            isDemoBannerDismissed: bootstrap.isDemoBannerDismissed
        )
        persistenceStatus = status
        dashboardModel = DashboardModel(
            providers: providers,
            container: bootstrap.container,
            credentials: bootstrap.credentials,
            clock: clock,
            // 截图和 UI 验收不该在生产库里建真信箱。默认仍然是 live。
            inboxClient: FeatureLaunchArguments.stubInbox ? .stub() : .live(),
            catalogResolver: catalogResolver,
            rateSource: rateSource,
            httpClient: httpClient,
            persistenceStatus: status
        )
        // 种子是刚才铺的，`bootstrap.containsDemoData` 那一份比它早，问仪表才准。
        status.containsDemoData = dashboardModel.containsDemoData()
        settingsModel = SettingsModel(
            dashboard: dashboardModel,
            persistenceStatus: persistenceStatus
        )
        usageAnalytics = Self.makeUsageAnalytics()
    }

    private static func makeUsageAnalytics() -> any UsageAnalyticsRecording {
        if FeatureLaunchArguments.stubUsageAnalytics { return NoOpUsageAnalytics() }
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return UsageAnalyticsClient(
            submitter: LiveUsage.submitter(),
            visitMarker: UserDefaultsVisitMarker(),
            platform: UsageAnalyticsPlatform.current,
            appVersion: "\(short) (\(build))"
        )
    }

    private static func makeProviders(
        clock: MeterClock,
        refreshBumpUSD: Decimal?,
        rateSource: SharedExchangeRates,
        httpClient: any HTTPClient
    ) -> [ProviderID: any BillingProvider] {
        // `now` 是闭包：适配器每次取数都重新读钟，跨月常驻后台也不会拿着启动那一刻的窗口。
        let assembled = ProviderAssembly.make(
            now: { clock.now },
            calendar: clock.calendar,
            httpClient: httpClient,
            rateSource: rateSource
        )
        #if DEBUG
        if let refreshBumpUSD {
            return assembled.mapValues {
                StampedBillingProvider(
                    provider: $0,
                    calendar: clock.calendar,
                    refreshBumpUSD: refreshBumpUSD
                )
            }
        }
        #endif
        return assembled
    }
}
