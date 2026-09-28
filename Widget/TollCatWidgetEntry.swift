import Foundation
import MeterDashboard
import SwiftData
import WidgetKit
import MeterCore
import MeterFormat
#if os(iOS)
import MeterGlance
#endif
import MeterModules
import MeterPersistence

/// 一格 widget 要画的东西：**哪一块模块**，加上和仪表盘同一份的内容。
///
/// 这里刻意不存「已经排好版的字」——内容一律走 `DashboardContentsBuilder`，
/// 和 App 里那份是同一次折算的同一套代码。Widget 自己攒一份精简数据的老路
/// 会让主屏上的数字和 App 里对不上，而且没有任何编译期信号。
struct TollCatWidgetEntry: TimelineEntry {
    var date: Date
    var module: DashboardModuleID
    var contents: DashboardContents
    var presentation: MoneyPresentation
    /// 一条账单都还没有。这时该说「还没有账单」，不是摆一个 $0。
    var isEmpty: Bool
}

/// 一块模块一条时间线。`module` 由生成出来的那个 widget kind 定死
/// （见 `TollCatWidgetBundle.swift`），所以这里没有配置参数——
/// 图库一行就是一块，加完不用再挑。
struct ModuleTimelineProvider: TimelineProvider {
    let module: DashboardModuleID

    func placeholder(in context: Context) -> TollCatWidgetEntry {
        TollCatWidgetLoader.empty(module: module, now: MeterClock.live.now)
    }

    /// 时钟走 `MeterClock.live`，不捡 `Calendar.current` / `Date.now`。
    ///
    /// 扩展是另一个进程，系统历法不是公历时（日本历 / 佛历）`Calendar.current`
    /// 的「本月」和主 App 的「本月」不是同一个月，`DayKey` 还原也按不同历法。
    /// `MeterClock` 搬进 Core 就是为了让两个进程用同一本日历，这头得接上。
    func getSnapshot(in context: Context, completion: @escaping (TollCatWidgetEntry) -> Void) {
        let clock = MeterClock.live
        completion(TollCatWidgetLoader.makeEntry(module: module, now: clock.now, calendar: clock.calendar))
    }

    /// 时间线里**只有一件事是系统该自己来的：跨月**。
    ///
    /// 别的刷新都由主 App 写完数据后主动触发（`WidgetTimelineReloader`），
    /// 所以这里曾经是 `policy: .never`。可跨月没有任何一次库写入会宣告——
    /// 9 月 1 日不打开 App，主屏那格就一直是 8 月的数字配着「本月」两个字，
    /// 而且会一直这样下去。
    ///
    /// 于是排两条：现在一条，下月月初一条；`policy` 也钉在那一刻，
    /// 系统在那之后来要新的时间线。主 App 随时可以抢在前面重载。
    func getTimeline(in context: Context, completion: @escaping (Timeline<TollCatWidgetEntry>) -> Void) {
        let clock = MeterClock.live
        let calendar = clock.calendar
        let now = clock.now
        var entries = [TollCatWidgetLoader.makeEntry(module: module, now: now, calendar: calendar)]
        guard let nextMonth = TollCatWidgetLoader.nextMonthStart(after: now, calendar: calendar) else {
            completion(Timeline(entries: entries, policy: .never))
            return
        }
        entries.append(
            TollCatWidgetLoader.makeEntry(module: module, now: nextMonth, calendar: calendar)
        )
        completion(Timeline(entries: entries, policy: .after(nextMonth)))
    }
}

enum TollCatWidgetLoader {
    /// Extension 进程里只开一次，避免每次刷新抢同一份 App Group store 文件。
    private static let container: ModelContainer? = try? PersistenceContainer.makeContainer()

    /// 只读缓存里的汇率。Widget 拿不到远程目录源——「Widget 不出网」靠结构保证，不靠自觉。
    private static let catalogResolver = CatalogResolver.readOnly()

    static func empty(
        module: DashboardModuleID,
        now: Date,
        presentation: MoneyPresentation = .usd
    ) -> TollCatWidgetEntry {
        TollCatWidgetEntry(
            date: now,
            module: module,
            contents: DashboardContents(),
            presentation: presentation,
            isEmpty: true
        )
    }

    static func makeEntry(
        module: DashboardModuleID,
        now: Date,
        calendar: Calendar,
        container: ModelContainer? = container
    ) -> TollCatWidgetEntry {
        guard let container,
              let store = try? SharedStoreReader.load(from: container, calendar: calendar, now: now),
              !store.isEmpty
        else {
            return empty(module: module, now: now)
        }
        // 账本折不到这个月（跨月了，主 App 还没重折过）：说「暂时没有数据」，
        // 不摆一个 $0，也不继续摆上个月那个数。见 `SharedStoreContents.canSpeak`。
        guard store.canSpeak(for: now, calendar: calendar) else {
            return TollCatWidgetEntry(
                date: now,
                module: module,
                contents: DashboardContents(),
                presentation: presentation(for: store),
                isEmpty: false
            )
        }
        return makeEntry(module: module, from: store, now: now, calendar: calendar)
    }

    #if os(iOS)
    /// 锁屏那几格要的一眼。和上面那格主屏 widget 读同一份库、走同一次折算，
    /// 只是最后多一步折成 `Glance`——手表那边收到的是 iPhone App 用同样几步折出来的一份
    /// （`WatchGlanceSource`），三处说的是同一个数。
    static func glance(now: Date, calendar: Calendar, container: ModelContainer? = container) -> Glance? {
        guard let container,
              let store = try? SharedStoreReader.load(from: container, calendar: calendar, now: now)
        else {
            return nil
        }
        let presentation = presentation(for: store)
        let canSpeak = !store.isEmpty && store.canSpeak(for: now, calendar: calendar)
        let contents = canSpeak
            ? contents(from: store, presentation: presentation, now: now, calendar: calendar)
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
    #endif

    private static func presentation(for store: SharedStoreContents) -> MoneyPresentation {
        MoneyPresentation(
            currencyCode: store.displayCurrency,
            rates: catalogResolver.current().exchangeRates
        )
    }

    /// 下个月 1 号零点。跨月是时间线里唯一一件系统该自己来的事。
    static func nextMonthStart(after now: Date, calendar: Calendar) -> Date? {
        guard
            let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            )
        else {
            return nil
        }
        return calendar.date(byAdding: .month, value: 1, to: monthStart)
    }

    /// 折算这一步和 App 走同一个入口。**这里不许出现第二套算法**——
    /// 主屏上的数字和 App 里的数字必须是同一份代码算出来的。
    static func makeEntry(
        module: DashboardModuleID,
        from store: SharedStoreContents,
        now: Date,
        calendar: Calendar
    ) -> TollCatWidgetEntry {
        let presentation = presentation(for: store)
        return TollCatWidgetEntry(
            date: now,
            module: module,
            contents: contents(from: store, presentation: presentation, now: now, calendar: calendar),
            presentation: presentation,
            isEmpty: false
        )
    }

    private static func contents(
        from store: SharedStoreContents,
        presentation: MoneyPresentation,
        now: Date,
        calendar: Calendar
    ) -> DashboardContents {
        // 取景框只跟订阅口径，构造收在 `SharedStoreContents.widgetFilter`：
        // Widget 永远是「本月 · 全部账号」。其余入参由 `widget(...)` 钉死，
        // 锁屏、手表走的是同一个入口。
        DashboardContentsBuilder.widget(
            view: store.view,
            filter: store.widgetFilter,
            now: now,
            calendar: calendar,
            presentation: presentation,
            connections: store.connections,
            layout: store.layout
        )
    }
}
