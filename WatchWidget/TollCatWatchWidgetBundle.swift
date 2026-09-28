import SwiftUI
import WidgetKit
import MeterGlance

/// 手表表盘和智能叠放那几格。和 iPhone 锁屏是同一张表、同一套视图；
/// 数从手表 App 落在 App Group 里的那个文件读——这个扩展自己不连 iPhone、不出网。
@main
struct TollCatWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchGlanceMonthWidget()
        WatchGlanceBudgetWidget()
    }
}

struct WatchGlanceMonthWidget: Widget {
    var body: some WidgetConfiguration {
        WatchGlanceConfiguration.make(.month)
    }
}

struct WatchGlanceBudgetWidget: Widget {
    var body: some WidgetConfiguration {
        WatchGlanceConfiguration.make(.budget)
    }
}

@MainActor
enum WatchGlanceConfiguration {
    static func make(_ kind: GlanceWidgetKind) -> some WidgetConfiguration {
        StaticConfiguration(kind: kind.kind, provider: WatchGlanceTimelineProvider()) { entry in
            GlanceWidgetView(kind: kind, glance: entry.glance, now: entry.date)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(kind.displayName)
        .description(kind.summary)
        .supportedFamilies(kind.families)
    }
}

struct WatchGlanceEntry: TimelineEntry {
    var date: Date
    var glance: Glance?
}

struct WatchGlanceTimelineProvider: TimelineProvider {
    private let store = GlanceStore.live()

    func placeholder(in context: Context) -> WatchGlanceEntry {
        WatchGlanceEntry(date: GlanceSamples.now, glance: GlanceSamples.month)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchGlanceEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(WatchGlanceEntry(date: .now, glance: store.load()))
    }

    /// 新数到了由手表 App 重载；这里只排「没人通知、但话该变」的那几刻。
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchGlanceEntry>) -> Void) {
        let now = Date.now
        let glance = store.load()
        let entries = GlanceTimeline.entryDates(for: glance, now: now).map { WatchGlanceEntry(date: $0, glance: glance) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
