#if os(iOS)
import SwiftUI
import WidgetKit
import MeterCore
import MeterGlance
import MeterModules

/// 锁屏那几格。和手表表盘是同一张表（`GlanceWidgetKind`）、同一套视图（`GlanceWidgetView`），
/// 这里只负责从 App Group 的库里读出一份 `Glance`。
///
/// 挂在生成出来的 `TollCatWidgetBundle` 末尾：主屏那几格按模块生成，
/// 这几格不是模块，不进 `shared/widgets.json`。Mac 的 widget 扩展也编这个目录，
/// 但 Mac 没有锁屏，所以整份只在 iOS 上编。
struct GlanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlanceMonthWidget()
        GlanceBudgetWidget()
    }
}

struct GlanceMonthWidget: Widget {
    var body: some WidgetConfiguration {
        GlanceWidgetConfiguration.make(GlanceWidgetKind.month)
    }
}

struct GlanceBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        GlanceWidgetConfiguration.make(GlanceWidgetKind.budget)
    }
}

@MainActor
enum GlanceWidgetConfiguration {
    static func make(_ kind: GlanceWidgetKind) -> some WidgetConfiguration {
        StaticConfiguration(kind: kind.kind, provider: GlanceTimelineProvider()) { entry in
            GlanceWidgetView(kind: kind, glance: entry.glance, now: entry.date)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(DashboardDeepLink.dashboardURL)
        }
        .configurationDisplayName(kind.displayName)
        .description(kind.summary)
        .supportedFamilies(kind.families)
    }
}

struct GlanceEntry: TimelineEntry {
    var date: Date
    var glance: Glance?
}

struct GlanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry {
        GlanceEntry(date: GlanceSamples.now, glance: GlanceSamples.month)
    }

    /// 时钟走 `MeterClock.live`，和主屏那几格同一本日历（理由见 `ModuleTimelineProvider`）。
    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let clock = MeterClock.live
        completion(GlanceEntry(date: clock.now, glance: TollCatWidgetLoader.glance(now: clock.now, calendar: clock.calendar)))
    }

    /// 数字只在主 App 写完库时变，那一下由 `WidgetTimelineReloader` 重载；
    /// 时间线里排的是没人通知、但话该变的那几刻（变旧、几小时前、跨月）。
    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        let clock = MeterClock.live
        let now = clock.now
        let glance = TollCatWidgetLoader.glance(now: now, calendar: clock.calendar)
        let entries = GlanceTimeline.entryDates(for: glance, now: now).map { GlanceEntry(date: $0, glance: glance) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
#endif
