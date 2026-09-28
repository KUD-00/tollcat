#if os(iOS)
import Foundation
import MeterDashboard
import SwiftData
import MeterCore
import MeterGlance
import MeterModules
import MeterPersistence

/// iPhone 这头折出要推给手表的那一份。
///
/// 和锁屏那几格（`TollCatWidgetLoader.glance`）是同样几步：读 App Group 里的库、
/// 走 `DashboardContentsBuilder.widget` 那一次折算、再折成 `Glance`。
/// 两处各写一遍是因为 widget 扩展链不到 MeterFeatures、MeterModules 又链不到库；
/// 真正会算错的那几步（折算、排字）两边调的是同一个函数。
enum WatchGlanceSource {
    static func make(container: ModelContainer, catalog: CatalogResolver, clock: MeterClock) -> Glance? {
        let now = clock.now
        let calendar = clock.calendar
        guard let store = try? SharedStoreReader.load(from: container, calendar: calendar, now: now) else {
            return nil
        }
        let presentation = MoneyPresentation(
            currencyCode: store.displayCurrency,
            rates: catalog.current().exchangeRates
        )
        let canSpeak = !store.isEmpty && store.canSpeak(for: now, calendar: calendar)
        let contents = canSpeak
            ? DashboardContentsBuilder.widget(
                view: store.view,
                filter: store.widgetFilter,
                now: now,
                calendar: calendar,
                presentation: presentation,
                connections: store.connections,
                layout: store.layout
            )
            : DashboardContents()
        return GlanceBuilder.make(
            contents: contents,
            isEmpty: store.isEmpty,
            canSpeak: canSpeak,
            budgetUSD: store.layout.monthlyBudgetUSD,
            lastRefreshAt: store.lastSuccessfulRefreshAt,
            presentation: presentation,
            now: now,
            calendar: calendar
        )
    }
}
#endif
